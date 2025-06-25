from dataclasses import dataclass, asdict

from layer_info import Conv2DShapeParam, MaxPool2DShapeParam

import math

# Memory
DATA_SIZE = 1  # Byte
PSUM_DATA_SIZE = 4  # Byte
BUS_BANDWIDTH = 4  # Byte

# Time
CLOCK_RATE = 200 * 1e6  # 200 MHz
TIME_UNIT = 1  # cycle
SPAD_ACCESS_TIME = 1 * TIME_UNIT
GLB_ACCESS_TIME = 2 * TIME_UNIT
DRAM_ACCESS_TIME = 5 * TIME_UNIT

# Energy
ENERGY_UNIT = 1e-6  # 1 pJ = 10^6 uJ
ENERGY_PER_MAC = 2 * ENERGY_UNIT
ENERGY_PER_GLB_ACCESS = 10 * ENERGY_UNIT
ENERGY_PER_DRAM_ACCESS = 200 * ENERGY_UNIT
POWER_UNIT = 1  # 1 uW
POWER_LEAKAGE = 50 * POWER_UNIT

######################################################################################################
# N: number of ifmaps/ofmaps
# M: number of filters
# H/W: ifmap height/width
# R/S: filter height/width
# E/F: ofmap height/width
# U: stride
#  ----------------------------------------------------------------------------------------------
# m: ofmap channels in global buffer
# n: number of ifmaps in a pass
# e: width of PE-set
# p: number of filters in a pass
# q: (ifmap or filter) channels in a pass
# r: number of PE sets for different (ifmap/filter) channels
# t: number of PE sets for different filters
#  ----------------------------------------------------------------------------------------------
#  Naming Convention
# *_per_pass: compute / storage size required per pass
# *_per_layer: compute / storage size required per layer
######################################################################################################


@dataclass
class EyerissHardwareParam:
    pe_array_h: int
    pe_array_w: int
    ifmap_spad_size: int
    filter_spad_size: int
    psum_spad_size: int
    glb_size: int
    bus_bw: int
    noc_bw: int


@dataclass
class EyerissMappingParam:
    m: int  # number of ofmap channels stored in global buffer
    n: int  # number of ofmaps/ifmaps used in a processing pass
    e: int  # width of the PE set (strip-mined if nessary)
    p: int  # number of filters processed by a PE set
    q: int  # number of ifmap/filter channels processed by a PE set
    r: int  # number of PE sets for different ifmap/filter channels
    t: int  # number of PE sets for different filters


AnalysisResult = dict[str, str | int | float]


class EyerissAnalyzer:
    cnt = 0

    def __init__(
        self,
        name: str | None = None,
        hardware_param: EyerissHardwareParam | None = None,
    ) -> None:
        self.name = name if name is not None else f"mapping_{EyerissAnalyzer.cnt}"
        self._hardware = hardware_param
        self._conv_shape = None
        self._maxpool_shape = None
        self._mapping = None
        EyerissAnalyzer.cnt += 1

    @property
    def hardware(self) -> EyerissHardwareParam:
        return self._hardware

    @hardware.setter
    def hardware(self, hardware_param: EyerissHardwareParam) -> None:
        assert isinstance(hardware_param, EyerissHardwareParam)
        self._hardware = hardware_param

    @property
    def conv_shape(self) -> Conv2DShapeParam:
        return self._conv_shape

    @conv_shape.setter
    def conv_shape(self, conv_param: Conv2DShapeParam) -> None:
        assert isinstance(conv_param, Conv2DShapeParam)
        self._conv_shape = conv_param

    @property
    def maxpool_shape(self) -> MaxPool2DShapeParam:
        return self._maxpool_shape

    @maxpool_shape.setter
    def maxpool_shape(self, maxpool_param: MaxPool2DShapeParam | None) -> None:
        assert isinstance(maxpool_param, (MaxPool2DShapeParam, type(None)))
        self._maxpool_shape = maxpool_param

    @property
    def mapping(self) -> EyerissMappingParam:
        return self._mapping

    @mapping.setter
    def mapping(self, mapping_param: EyerissMappingParam) -> None:
        self._mapping = mapping_param

    # Scratchpad Memory Usage
    def filter_used(self) -> int:
        return self.mapping.q * self.conv_shape.S * self.mapping.p

    def ifmap_used(self) -> int:
        return self.mapping.q * self.conv_shape.S

    def psum_used(self) -> int:
        return self.mapping.p

    @property
    def spad_size_legal(self) -> dict[str, bool]:
        return {
            "ifmap": self.ifmap_used() <= self.hardware.ifmap_spad_size,
            "filter": self.filter_used() <= self.hardware.filter_spad_size,
            "psum": self.psum_used() <= self.hardware.psum_spad_size,
        }

    # Global Buffer (GLB) Usage
    #! <<<========= Implement here =========>>>
    @property
    def glb_usage_per_pass(self) -> dict[str, int]:
        conv = self.conv_shape      # Conv2DShapeParam，包含 N, R, S, W, F, U 等
        mapping = self.mapping      # EyerissMappingParam，包含 n, m, e, p, q, r, t

        # ifmap usage
        # 公式：ifmap_usage = n × (q × r) × ((U × (e - 1)) + R) × W × 1 byte
        ifmap_usage = mapping.n * (mapping.q * mapping.r) * ((conv.U * (mapping.e - 1)) + conv.R) * conv.W * DATA_SIZE

        # filter usage
        # 公式：filter_usage = (p × t) × (q × r) × R × S × 1 byte
        # depthwise + pointwise
        filter_usage = (mapping.q * mapping.r) * conv.R * conv.S * DATA_SIZE \
                     + (mapping.p * mapping.t) * (mapping.q * mapping.r) * DATA_SIZE

        # bias usage
        # 公式：bias_usage = (p × t) × 4 bytes
        bias_usage = (mapping.p * mapping.t) * 4

        # psum usage
        # 公式：psum_usage = n × m × e × F × 4 bytes
        psum_usage = mapping.n * mapping.m * mapping.e * conv.F * PSUM_DATA_SIZE

        # 最終 total_usage = ifmap + filter + bias + psum
        total_usage = ifmap_usage + filter_usage + bias_usage + psum_usage

        return {
            "ifmap": ifmap_usage, 
            "filter": filter_usage,
            "bias": bias_usage,
            "psum": psum_usage,
            "total": total_usage,
        }
    @property
    def glb_size_legal(self) -> bool:
        return self.glb_usage_per_pass["total"] <= self.hardware.glb_size

    @property
    def dram_access_per_layer(self) -> dict[str, int]:
        ifmap_read = 0
        filter_read = 0
        bias_read = 0
        ofmap_write = 0

        # ------------- Conv2D -------------
        if self._conv_shape is not None:
            conv = self.conv_shape
            mapping = self.mapping

            # (1) Ifmap DRAM Reads
            tile_size_ifmap = (
                mapping.n *
                (mapping.q * mapping.r) *
                ((conv.U * (mapping.e - 1)) + conv.R) *
                conv.W * DATA_SIZE
            )
            num_ifmap_tiles = (
                math.ceil(conv.M / mapping.m) *
                math.ceil(conv.N / mapping.n) *
                math.ceil(conv.E / mapping.e) *
                math.ceil(conv.C / (mapping.q * mapping.r))
            )
            ifmap_read = num_ifmap_tiles * tile_size_ifmap

            # (2) Filter DRAM Reads
            tile_size_filter_depth = (
                (mapping.q * mapping.r) *
                conv.R * conv.S * DATA_SIZE
            )
            tile_size_filter_point = (
                (mapping.p * mapping.t) *
                (mapping.q * mapping.r) *
                DATA_SIZE
            )
            num_filter_tiles_depth = (
                math.ceil(conv.M / (mapping.m)) *
                math.ceil(conv.N / mapping.n) *
                math.ceil(conv.E / mapping.e) *
                math.ceil(conv.C / (mapping.q * mapping.r))
            )
            num_filter_tiles_point = (
                math.ceil(conv.M / (mapping.m)) *
                math.ceil(mapping.m / (mapping.p * mapping.t)) *
                math.ceil(conv.N / mapping.n) *
                math.ceil(conv.E / mapping.e) *
                math.ceil(conv.C / (mapping.q * mapping.r))
            )
            filter_read = num_filter_tiles_depth * tile_size_filter_depth \
                        + num_filter_tiles_point * tile_size_filter_point   

            # (3) Bias DRAM Reads
            tile_size_bias = (mapping.p * mapping.t) * 4  # 32-bit => 4 bytes
            num_bias_tiles = (
                math.ceil(conv.M / (mapping.m)) *
                math.ceil(mapping.m / (mapping.p * mapping.t)) *
                math.ceil(conv.N / mapping.n) *
                math.ceil(conv.E / mapping.e)
            )
            bias_read = num_bias_tiles * tile_size_bias

            # (4) Ofmap DRAM Writes
            # 下面以 "e_out" 和 "f_out" 表示實際寫回的輸出維度
            e_out = mapping.e
            f_out = conv.F

            if self._maxpool_shape is not None:
                #依 self._maxpool_shape.kernel_size 與 stride 推導)
                e_out = math.ceil(mapping.e / self.maxpool_shape.kernel_size)
                f_out = math.ceil(conv.F / self.maxpool_shape.stride)

            tile_ofmap = (mapping.n * mapping.m) * e_out * f_out * DATA_SIZE
            num_ofmap_tiles = (
                math.ceil(conv.M / mapping.m) *
                math.ceil(conv.N / mapping.n) *
                math.ceil(conv.E / mapping.e) 
            )
            ofmap_write = num_ofmap_tiles * tile_ofmap

        # ----------------------------
        # 總 DRAM 存取量
        # ----------------------------
        total_read = ifmap_read + filter_read + bias_read
        total_write =  ofmap_write
        total = total_read + total_write

        return {
            "ifmap_read":   ifmap_read,
            "filter_read":  filter_read,
            "bias_read":    bias_read,
            "ofmap_write":  ofmap_write,
            "read":         total_read,
            "write":        total_write,
            "total":        total,
        }

    # GLB Accesses (GLB-Spad data movement)
    #! <<<========= Implement here =========>>>
    @property
    def glb_access_per_layer(self) -> dict[str, int]:
        conv = self.conv_shape
        mapping = self.mapping

        # 預設都為 0
        ifmap_read   = 0
        filter_read  = 0
        bias_read    = 0
        psum_read    = 0
        psum_write   = 0

        # -----------------------------------------------------------------
        # (1) IFMAP GLB Reads
        # -----------------------------------------------------------------
        tile_size_ifmap = (
            mapping.n
            * (mapping.q * mapping.r)
            * ((conv.U * (mapping.e - 1)) + conv.R)
            * conv.W
            # 每個 element 1 byte
        )
        # tile 數量
        num_ifmap_tiles = (
            math.ceil(conv.M / mapping.m)
            * math.ceil(conv.N / mapping.n)
            * math.ceil(conv.E / mapping.e)
            * math.ceil(conv.C / (mapping.q * mapping.r))
        )
        # reuse factor
        reuse_ifmap = math.ceil(mapping.m / (mapping.p * mapping.t))

        ifmap_read = num_ifmap_tiles * reuse_ifmap * tile_size_ifmap

        # -----------------------------------------------------------------
        # (2) Filter GLB Reads
        # -----------------------------------------------------------------
        tile_size_filter_depth = (
            (mapping.q * mapping.r) *
            conv.R * conv.S * DATA_SIZE
        )
        tile_size_filter_point = (
            (mapping.p * mapping.t) *
            (mapping.q * mapping.r) *
            DATA_SIZE
        )
        num_filter_tiles_depth = (
            math.ceil(conv.M / (mapping.m)) *
            math.ceil(conv.N / mapping.n) *
            math.ceil(conv.E / mapping.e) *
            math.ceil(conv.C / (mapping.q * mapping.r))
        )
        num_filter_tiles_point = (
            math.ceil(conv.M / (mapping.m)) *
            math.ceil(mapping.m/ (mapping.p * mapping.t)) *
            math.ceil(conv.N / mapping.n) *
            math.ceil(conv.E / mapping.e) *
            math.ceil(conv.C / (mapping.q * mapping.r))
        )
        filter_read = num_filter_tiles_depth * tile_size_filter_depth \
                        + num_filter_tiles_point * tile_size_filter_point   
        # -----------------------------------------------------------------
        # (3) Bias GLB Reads
        # -----------------------------------------------------------------
        tile_size_bias = (mapping.p * mapping.t) * 4  # bias: 32-bit => 4 bytes
        num_bias_tiles = (
            math.ceil(conv.M / mapping.m)
            * math.ceil(mapping.m / (mapping.p * mapping.t))
            * math.ceil(conv.N / mapping.n)
            * math.ceil(conv.E / mapping.e)
        )
        bias_read = num_bias_tiles * tile_size_bias

        # -----------------------------------------------------------------
        # (4) Psum 相關 (中途 & 最終)
        # -----------------------------------------------------------------
        # 假設中途 psum 單次大小 = n*m*e*F * 4 bytes
        psum_tile = mapping.n * mapping.m * mapping.e * conv.F * 4

        # c 方向的 tile 數
        c_tiles = math.ceil(conv.C / (mapping.q * mapping.r))

        # 前 (c_tiles - 1) 次需要先讀舊 psum，再寫新的 psum
        psum_read_tiles = (
                (c_tiles - 1)
                * math.ceil(conv.M / mapping.m)
                * math.ceil(conv.E / mapping.e)
                * math.ceil(conv.N / mapping.n)
        )
        psum_write_tiles = (
                (c_tiles)
                * math.ceil(conv.M / mapping.m)
                * math.ceil(conv.E / mapping.e)
                * math.ceil(conv.N / mapping.n)
        )
        psum_read  = psum_read_tiles * psum_tile
        psum_write = psum_write_tiles * psum_tile

        # (5) Ofmap GLB read & Writes
        # 下面以 "e_out" 和 "f_out" 表示實際寫回的輸出維度

        ofmap_tile = mapping.n * mapping.m * mapping.e * conv.F * 4

        # 前 (c_tiles - 1) 次需要先讀舊 psum，再寫新的 psum
        ofmap_read_tiles = (
                 math.ceil(conv.M / mapping.m)
                * math.ceil(conv.E / mapping.e)
                * math.ceil(conv.N / mapping.n)
        )

        ofmap_read = ofmap_read_tiles * ofmap_tile

        e_out = mapping.e
        f_out = conv.F

        if self._maxpool_shape is not None:
            #依 self._maxpool_shape.kernel_size 與 stride 推導)
            e_out = math.ceil(mapping.e / self.maxpool_shape.kernel_size)
            f_out = math.ceil(conv.F / self.maxpool_shape.stride)

        tile_ofmap = (mapping.n * mapping.m) * e_out * f_out * DATA_SIZE
        num_ofmap_tiles = (
            math.ceil(conv.M / mapping.m) *
            math.ceil(conv.E / mapping.e) *
            math.ceil(conv.N / mapping.n) 
            
        )
        ofmap_write = num_ofmap_tiles * tile_ofmap
        # -----------------------------------------------------------------
        # (6) 統整
        # -----------------------------------------------------------------
        glb_read = ifmap_read + filter_read + bias_read + psum_read + ofmap_read 
        glb_write = psum_write + ofmap_write
        glb_total = glb_read + glb_write

        return {
            "ifmap_read":   ifmap_read,
            "filter_read":  filter_read,
            "bias_read":    bias_read,
            "psum_read":    psum_read,
            "psum_write":   psum_write,
            "read":         glb_read,
            "write":        glb_write,
            "total":        glb_total,
        }

    @property
    def latency_per_layer(self) -> int:
        ofmap_size = (
            self.conv_shape.N
            * self.conv_shape.M
            * self.conv_shape.E
            * self.conv_shape.F
        )
        ppu_latency_per_elem = 1 if self.maxpool_shape is None else 5

        # 延遲（latency）計算時要將它們除以 BUS_BANDWIDTH
        dram_cycles = (self.dram_access_per_layer["total"] / self.hardware.bus_bw) * DRAM_ACCESS_TIME
        glb_cycles  = (self.glb_access_per_layer["total"] / self.hardware.bus_bw) * GLB_ACCESS_TIME

        return int(dram_cycles + glb_cycles + ofmap_size * ppu_latency_per_elem)

    @property
    def macs_per_layer(self) -> int:
        '''
        return (
            self.conv_shape.N
            * self.conv_shape.M
            * self.conv_shape.E
            * self.conv_shape.F
            * self.conv_shape.C
            * self.conv_shape.R
            * self.conv_shape.S
        )        
        '''
        return (
            (self.conv_shape.M
            * self.conv_shape.E
            * self.conv_shape.F
            * self.conv_shape.R
            * self.conv_shape.S)
            + (self.conv_shape.M
            * self.conv_shape.C  
            * self.conv_shape.E
            * self.conv_shape.F)
        )

    @property
    def energy_per_layer(self) -> dict[str, float]:
        compute_energy = self.macs_per_layer * ENERGY_PER_MAC
        memory_energy = (
            self.glb_access_per_layer["total"] * ENERGY_PER_GLB_ACCESS
            + self.dram_access_per_layer["total"] * ENERGY_PER_DRAM_ACCESS
        )
        leakage_energy = POWER_LEAKAGE * self.latency_per_layer / CLOCK_RATE
        total_energy = compute_energy + memory_energy + leakage_energy
        return {
            "compute": compute_energy,
            "memory": memory_energy,
            "leakage": leakage_energy,
            "total": total_energy,
        }

    @property
    def power_per_layer(self) -> dict[str, float]:
        compute_power = (
            self.energy_per_layer["compute"] / self.latency_per_layer * CLOCK_RATE
        )
        memory_power = (
            self.energy_per_layer["memory"] / self.latency_per_layer * CLOCK_RATE
        )
        leakage_power = POWER_LEAKAGE
        total_power = compute_power + memory_power + leakage_power
        return {
            "compute": compute_power,
            "memory": memory_power,
            "leakage": leakage_power,
            "total": total_power,
        }

    @property
    def operational_intensity(self) -> float:
        return self.macs_per_layer / self.dram_access_per_layer["total"]

    @property
    def peak_performance(self) -> float:
        return self.hardware.pe_array_h * self.hardware.pe_array_w  # MACs per cycle

    @property
    def peak_bandwidth(self) -> float:
        return self.hardware.bus_bw  # bytes per cycle

    @property
    def bound_by(self) -> str:
        machine_blance_point = self.peak_performance / self.peak_bandwidth
        if self.operational_intensity > machine_blance_point:
            return "compute"
        elif self.operational_intensity < machine_blance_point:
            return "memory"
        else:
            return "balanced"

    @property
    def is_compute_bound(self) -> bool:
        return self.bound_by == "compute"

    @property
    def is_memory_bound(self) -> bool:
        return self.bound_by == "memory"

    @property
    def is_balanced(self) -> bool:
        return self.bound_by == "balanced"

    @property
    def summary(self) -> AnalysisResult:
        return {
            "layer": self.name,
            #**asdict(self.hardware),
            "glb_usage": self.glb_usage_per_pass["total"],  # bytes
            "glb_read": self.glb_access_per_layer["read"],  # bytes
            "glb_write": self.glb_access_per_layer["write"],  # bytes
            "glb_access": self.glb_access_per_layer["total"],  # bytes

            "dram_read": self.dram_access_per_layer["read"],  # bytes
            "dram_write": self.dram_access_per_layer["write"],  # bytes
            "dram_access": self.dram_access_per_layer["total"],  # bytes
            
            "macs": self.macs_per_layer,
            "latency": self.latency_per_layer,  # cycles
            "energy_per_layer":self.energy_per_layer["total"],
            "power_per_layer":self.power_per_layer["total"],
            **asdict(self.mapping),
            "Latency": self.latency_per_layer, 
            # or any other metrics you want to include in the report
            
        }
