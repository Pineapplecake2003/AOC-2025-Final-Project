from heapq import nsmallest, nlargest
from itertools import product

from analytical_model.eyeriss import (
    EyerissAnalyzer,
    AnalysisResult,
    EyerissHardwareParam,
    EyerissMappingParam,
    PSUM_DATA_SIZE,
)
from layer_info import Conv2DShapeParam, MaxPool2DShapeParam


class EyerissMapper:
    cnt = 0

    def __init__(
        self,
        name: str | None,
    ) -> None:
        self.name = name if name is not None else f"mapping_{EyerissMapper.cnt}"
        self.analyzer = EyerissAnalyzer(name=self.name)
        EyerissMapper.cnt += 1

    def run(
        self,
        conv2d: Conv2DShapeParam,
        maxpool: MaxPool2DShapeParam | None = None,
        num_solutions: int = 1,
    ) -> list[AnalysisResult]:
        self.analyzer.conv_shape = conv2d
        self.analyzer.maxpool_shape = maxpool
        results = []

        for hardware in self.generate_hardware():
            self.hardware = hardware

            for mapping in self.generate_mappings():
                self.analyzer.mapping = mapping
                res = self.analyzer.summary
                results.append(res)


        # 打印出所有候選解的 metrics 與 evaluate 分數
        '''
        print("==== Candidate Solutions ====")
        for idx, res in enumerate(results):
            score = self.evaluate(res)
            print(f"Candidate {idx}:")
            print("Metrics:", res)
            print("Evaluation Score:", score)
            print("----------------------------")'
        '''

        results = nlargest(num_solutions, results, key=self.evaluate)
        return results

    def evaluate(self, metrics: AnalysisResult) -> float:
        epsilon = 1e-7  # 防止除零

        latency = metrics.get("latency", 1)
        dram_access = metrics.get("dram_access", 1)
        glb_access = metrics.get("glb_access", 1)
        glb_usage = metrics.get("glb_usage", 1)
        
        
        # 定義權重
        weight_latency = 0  # % latency
        weight_glb_access = 0.3
        weight_dram_access = 0.7
        weight_glb_usage = 0
        
        # 用 1 / (weight和)
        score = 1.0 / (weight_latency * latency + weight_glb_access * glb_access + weight_dram_access * dram_access + weight_glb_usage * glb_usage + epsilon)
        return score

    @property
    def hardware(self) -> EyerissHardwareParam:
        return self.analyzer.hardware

    @hardware.setter
    def hardware(self, hardware_param: EyerissHardwareParam) -> None:
        assert isinstance(hardware_param, EyerissHardwareParam)
        self.analyzer.hardware = hardware_param

    def p_avaliable(self) -> list[int]:
        # normal pe case (psum spad size is 16)
        p_max = (self.hardware.psum_spad_size // 2) // PSUM_DATA_SIZE
        return list(range(1, p_max + 1))

    def q_avaliable(self) -> list[int]:
        q_max = self.hardware.ifmap_spad_size // self.analyzer.conv_shape.S
        return list(range(1, q_max + 1))

    def e_available(self) -> list[int]:
        hw_strips = self.hardware.pe_array_h // self.analyzer.conv_shape.R
        e_max = self.hardware.pe_array_w * hw_strips
        return list(range(1, min(e_max, self.analyzer.conv_shape.E) + 1))

    def r_available(self) -> list[int]:
        r_max = self.hardware.pe_array_h // self.analyzer.conv_shape.R
        return list(range(1, r_max + 1))

    def t_available(self) -> list[int]:
        num_pes = self.hardware.pe_array_h * self.hardware.pe_array_w
        t_max = num_pes // self.analyzer.conv_shape.R
        return list(range(1, t_max + 1))

    def m_available(self) -> list[int]:
        m_max = self.analyzer.conv_shape.M
        return list(
            m for m in range(1, m_max + 1) if self.analyzer.conv_shape.M % m == 0
        )

    def validate(self, mapping) -> bool:
        m, n, e, p, q, r, t = mapping

        # filter_spad_size limitations
        if self.analyzer.conv_shape.S * q + p * q > self.hardware.filter_spad_size:
            return False

        # psum_spad_size limitations
        # super pe case (psum size is 32)
        if (q + p > self.hardware.psum_spad_size // 4):
            return False

        # e 約束條件：e 必須與 PE 陣列寬度相關或等於輸出高度
        if (
            e % self.hardware.pe_array_w != 0
            and e != self.hardware.pe_array_w // 2
            and self.analyzer.conv_shape.E != e
        ):
            return False

        # rt 約束條件：r * t 必須等於 (pe_array_h * pe_array_w) / (conv.R * e)
        if (
            r * t
            != self.hardware.pe_array_h
            * self.hardware.pe_array_w
            // self.analyzer.conv_shape.R
            // e
        ):
            return False

        # m 約束條件：m 必須能被 p 整除
        if m % p != 0:
            return False

        return True

    def generate_mappings(self) -> list[EyerissMappingParam]:
        n_avaliable_list = [1]
        p_available_list = self.p_avaliable()
        q_available_list = self.q_avaliable()
        e_available_list = self.e_available()
        r_available_list = self.r_available()
        t_available_list = self.t_available()
        m_available_list = self.m_available()

        candidate_solutions = product(
            m_available_list,
            n_avaliable_list,
            e_available_list,
            p_available_list,
            q_available_list,
            r_available_list,
            t_available_list,
        )
        valid_solutions = [
            EyerissMappingParam(m, n, e, p, q, r, t)
            for (m, n, e, p, q, r, t) in candidate_solutions
                if self.validate((m, n, e, p, q, r, t))
        ]
        return valid_solutions

    def generate_hardware(self) -> list[EyerissHardwareParam]:
        pe_array_h_list = [6]
        pe_array_w_list = [8]
        ifmap_spad_size_list = [12]
        filter_spad_size_list = [48]
        psum_spad_size_list = [32] # SUPER PE psum spad size
        glb_size_list = [64 * 2**10]
        bus_bw_list = [4]
        noc_bw_list = [4]

        candidate_solutions = product(
            pe_array_h_list,
            pe_array_w_list,
            ifmap_spad_size_list,
            filter_spad_size_list,
            psum_spad_size_list,
            glb_size_list,
            bus_bw_list,
            noc_bw_list,
        )
        candidate_solutions = [EyerissHardwareParam(*m) for m in candidate_solutions]
        return candidate_solutions
