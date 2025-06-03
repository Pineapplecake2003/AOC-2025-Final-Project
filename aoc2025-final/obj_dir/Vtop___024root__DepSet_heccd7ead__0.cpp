// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop.h for the primary calling header

#include "Vtop__pch.h"
#include "Vtop___024root.h"

void Vtop___024root___ico_sequent__TOP__0(Vtop___024root* vlSelf);

void Vtop___024root___eval_ico(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_ico\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vtop___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vtop___024root___ico_sequent__TOP__0(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___ico_sequent__TOP__0\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.top__DOT__dma_inst__DOT__ns = ((4U & (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))
                                              ? 0U : 
                                             ((2U & (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))
                                               ? ((1U 
                                                   & (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))
                                                   ? 
                                                  (((IData)(vlSelfRef.top__DOT__dma_inst__DOT__counter) 
                                                    == 
                                                    ((IData)(vlSelfRef.top__DOT__dma_inst__DOT__len) 
                                                     - (IData)(1U)))
                                                    ? 4U
                                                    : 2U)
                                                   : 3U)
                                               : ((1U 
                                                   & (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))
                                                   ? 2U
                                                   : 
                                                  ((IData)(vlSelfRef.start)
                                                    ? 1U
                                                    : 0U))));
}

void Vtop___024root___eval_triggers__ico(Vtop___024root* vlSelf);

bool Vtop___024root___eval_phase__ico(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__ico\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vtop___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vtop___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vtop___024root___eval_act(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_act\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
}

void Vtop___024root___nba_sequent__TOP__0(Vtop___024root* vlSelf);

void Vtop___024root___eval_nba(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_nba\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((3ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vtop___024root___nba_sequent__TOP__0(vlSelf);
        vlSelfRef.__Vm_traceActivity[1U] = 1U;
    }
}

VL_INLINE_OPT void Vtop___024root___nba_sequent__TOP__0(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___nba_sequent__TOP__0\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Init
    SData/*15:0*/ __Vdly__top__DOT__dma_inst__DOT__counter;
    __Vdly__top__DOT__dma_inst__DOT__counter = 0;
    IData/*31:0*/ __Vdly__top__DOT__dma_inst__DOT__read_ptr;
    __Vdly__top__DOT__dma_inst__DOT__read_ptr = 0;
    IData/*31:0*/ __Vdly__top__DOT__dma_inst__DOT__write_ptr;
    __Vdly__top__DOT__dma_inst__DOT__write_ptr = 0;
    SData/*15:0*/ __Vdly__top__DOT__dma_inst__DOT__len;
    __Vdly__top__DOT__dma_inst__DOT__len = 0;
    CData/*7:0*/ __VdlyVal__top__DOT__glb_inst__DOT__mem__v0;
    __VdlyVal__top__DOT__glb_inst__DOT__mem__v0 = 0;
    SData/*15:0*/ __VdlyDim0__top__DOT__glb_inst__DOT__mem__v0;
    __VdlyDim0__top__DOT__glb_inst__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__top__DOT__glb_inst__DOT__mem__v0;
    __VdlySet__top__DOT__glb_inst__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__top__DOT__glb_inst__DOT__mem__v1;
    __VdlyVal__top__DOT__glb_inst__DOT__mem__v1 = 0;
    SData/*15:0*/ __VdlyDim0__top__DOT__glb_inst__DOT__mem__v1;
    __VdlyDim0__top__DOT__glb_inst__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__top__DOT__glb_inst__DOT__mem__v2;
    __VdlyVal__top__DOT__glb_inst__DOT__mem__v2 = 0;
    SData/*15:0*/ __VdlyDim0__top__DOT__glb_inst__DOT__mem__v2;
    __VdlyDim0__top__DOT__glb_inst__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__top__DOT__glb_inst__DOT__mem__v3;
    __VdlyVal__top__DOT__glb_inst__DOT__mem__v3 = 0;
    SData/*15:0*/ __VdlyDim0__top__DOT__glb_inst__DOT__mem__v3;
    __VdlyDim0__top__DOT__glb_inst__DOT__mem__v3 = 0;
    // Body
    __Vdly__top__DOT__dma_inst__DOT__write_ptr = vlSelfRef.top__DOT__dma_inst__DOT__write_ptr;
    __Vdly__top__DOT__dma_inst__DOT__read_ptr = vlSelfRef.top__DOT__dma_inst__DOT__read_ptr;
    __Vdly__top__DOT__dma_inst__DOT__counter = vlSelfRef.top__DOT__dma_inst__DOT__counter;
    __Vdly__top__DOT__dma_inst__DOT__len = vlSelfRef.top__DOT__dma_inst__DOT__len;
    __VdlySet__top__DOT__glb_inst__DOT__mem__v0 = 0U;
    if ((1U & (~ (IData)(vlSelfRef.rst)))) {
        if ((3U == (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))) {
            __VdlyVal__top__DOT__glb_inst__DOT__mem__v0 
                = (0xffU & vlSelfRef.mem_read_data);
            __VdlyDim0__top__DOT__glb_inst__DOT__mem__v0 
                = (0xffffU & vlSelfRef.top__DOT__dma_inst__DOT__write_ptr);
            __VdlySet__top__DOT__glb_inst__DOT__mem__v0 = 1U;
            __VdlyVal__top__DOT__glb_inst__DOT__mem__v1 
                = (0xffU & (vlSelfRef.mem_read_data 
                            >> 8U));
            __VdlyDim0__top__DOT__glb_inst__DOT__mem__v1 
                = (0xffffU & ((IData)(1U) + vlSelfRef.top__DOT__dma_inst__DOT__write_ptr));
            __VdlyVal__top__DOT__glb_inst__DOT__mem__v2 
                = (0xffU & (vlSelfRef.mem_read_data 
                            >> 0x10U));
            __VdlyDim0__top__DOT__glb_inst__DOT__mem__v2 
                = (0xffffU & ((IData)(2U) + vlSelfRef.top__DOT__dma_inst__DOT__write_ptr));
            __VdlyVal__top__DOT__glb_inst__DOT__mem__v3 
                = (vlSelfRef.mem_read_data >> 0x18U);
            __VdlyDim0__top__DOT__glb_inst__DOT__mem__v3 
                = (0xffffU & ((IData)(3U) + vlSelfRef.top__DOT__dma_inst__DOT__write_ptr));
        }
    }
    if (vlSelfRef.rst) {
        __Vdly__top__DOT__dma_inst__DOT__counter = 0U;
        __Vdly__top__DOT__dma_inst__DOT__read_ptr = 0U;
        __Vdly__top__DOT__dma_inst__DOT__write_ptr = 0U;
        __Vdly__top__DOT__dma_inst__DOT__len = 0U;
        vlSelfRef.glb_dout = 0U;
        vlSelfRef.top__DOT__dma_inst__DOT__cs = 0U;
    } else {
        if ((0U == (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))) {
            __Vdly__top__DOT__dma_inst__DOT__counter = 0U;
            __Vdly__top__DOT__dma_inst__DOT__read_ptr 
                = vlSelfRef.src_addr;
            __Vdly__top__DOT__dma_inst__DOT__write_ptr 
                = vlSelfRef.dst_addr;
            __Vdly__top__DOT__dma_inst__DOT__len = vlSelfRef.length;
        } else if ((3U == (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))) {
            __Vdly__top__DOT__dma_inst__DOT__counter 
                = (0xffffU & ((IData)(1U) + (IData)(vlSelfRef.top__DOT__dma_inst__DOT__counter)));
            __Vdly__top__DOT__dma_inst__DOT__read_ptr 
                = ((IData)(4U) + vlSelfRef.top__DOT__dma_inst__DOT__read_ptr);
            __Vdly__top__DOT__dma_inst__DOT__write_ptr 
                = ((IData)(4U) + vlSelfRef.top__DOT__dma_inst__DOT__write_ptr);
        } else {
            __Vdly__top__DOT__dma_inst__DOT__counter 
                = vlSelfRef.top__DOT__dma_inst__DOT__counter;
            __Vdly__top__DOT__dma_inst__DOT__read_ptr 
                = vlSelfRef.top__DOT__dma_inst__DOT__read_ptr;
            __Vdly__top__DOT__dma_inst__DOT__write_ptr 
                = vlSelfRef.top__DOT__dma_inst__DOT__write_ptr;
            __Vdly__top__DOT__dma_inst__DOT__len = vlSelfRef.top__DOT__dma_inst__DOT__len;
        }
        vlSelfRef.glb_dout = ((vlSelfRef.top__DOT__glb_inst__DOT__mem
                               [(0xffffU & ((IData)(3U) 
                                            + vlSelfRef.glb_r_addr))] 
                               << 0x18U) | ((vlSelfRef.top__DOT__glb_inst__DOT__mem
                                             [(0xffffU 
                                               & ((IData)(2U) 
                                                  + vlSelfRef.glb_r_addr))] 
                                             << 0x10U) 
                                            | ((vlSelfRef.top__DOT__glb_inst__DOT__mem
                                                [(0xffffU 
                                                  & ((IData)(1U) 
                                                     + vlSelfRef.glb_r_addr))] 
                                                << 8U) 
                                               | vlSelfRef.top__DOT__glb_inst__DOT__mem
                                               [(0xffffU 
                                                 & vlSelfRef.glb_r_addr)])));
        vlSelfRef.top__DOT__dma_inst__DOT__cs = vlSelfRef.top__DOT__dma_inst__DOT__ns;
    }
    vlSelfRef.top__DOT__dma_inst__DOT__read_ptr = __Vdly__top__DOT__dma_inst__DOT__read_ptr;
    vlSelfRef.top__DOT__dma_inst__DOT__counter = __Vdly__top__DOT__dma_inst__DOT__counter;
    vlSelfRef.top__DOT__dma_inst__DOT__len = __Vdly__top__DOT__dma_inst__DOT__len;
    vlSelfRef.top__DOT__dma_inst__DOT__write_ptr = __Vdly__top__DOT__dma_inst__DOT__write_ptr;
    if (__VdlySet__top__DOT__glb_inst__DOT__mem__v0) {
        vlSelfRef.top__DOT__glb_inst__DOT__mem[__VdlyDim0__top__DOT__glb_inst__DOT__mem__v0] 
            = __VdlyVal__top__DOT__glb_inst__DOT__mem__v0;
        vlSelfRef.top__DOT__glb_inst__DOT__mem[__VdlyDim0__top__DOT__glb_inst__DOT__mem__v1] 
            = __VdlyVal__top__DOT__glb_inst__DOT__mem__v1;
        vlSelfRef.top__DOT__glb_inst__DOT__mem[__VdlyDim0__top__DOT__glb_inst__DOT__mem__v2] 
            = __VdlyVal__top__DOT__glb_inst__DOT__mem__v2;
        vlSelfRef.top__DOT__glb_inst__DOT__mem[__VdlyDim0__top__DOT__glb_inst__DOT__mem__v3] 
            = __VdlyVal__top__DOT__glb_inst__DOT__mem__v3;
    }
    vlSelfRef.mem_read_addr = vlSelfRef.top__DOT__dma_inst__DOT__read_ptr;
    vlSelfRef.mem_length = vlSelfRef.top__DOT__dma_inst__DOT__len;
    vlSelfRef.done = (4U == (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs));
    vlSelfRef.notify_host = (1U == (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs));
    vlSelfRef.top__DOT__dma_inst__DOT__ns = ((4U & (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))
                                              ? 0U : 
                                             ((2U & (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))
                                               ? ((1U 
                                                   & (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))
                                                   ? 
                                                  (((IData)(vlSelfRef.top__DOT__dma_inst__DOT__counter) 
                                                    == 
                                                    ((IData)(vlSelfRef.top__DOT__dma_inst__DOT__len) 
                                                     - (IData)(1U)))
                                                    ? 4U
                                                    : 2U)
                                                   : 3U)
                                               : ((1U 
                                                   & (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))
                                                   ? 2U
                                                   : 
                                                  ((IData)(vlSelfRef.start)
                                                    ? 1U
                                                    : 0U))));
}

void Vtop___024root___eval_triggers__act(Vtop___024root* vlSelf);

bool Vtop___024root___eval_phase__act(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__act\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<2> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vtop___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vtop___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vtop___024root___eval_phase__nba(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__nba\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vtop___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__ico(Vtop___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__nba(Vtop___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__act(Vtop___024root* vlSelf);
#endif  // VL_DEBUG

void Vtop___024root___eval(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VicoIterCount;
    CData/*0:0*/ __VicoContinue;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VicoIterCount = 0U;
    vlSelfRef.__VicoFirstIteration = 1U;
    __VicoContinue = 1U;
    while (__VicoContinue) {
        if (VL_UNLIKELY((0x64U < __VicoIterCount))) {
#ifdef VL_DEBUG
            Vtop___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("src/Controller/top.sv", 4, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vtop___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            Vtop___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("src/Controller/top.sv", 4, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelfRef.__VactIterCount))) {
#ifdef VL_DEBUG
                Vtop___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("src/Controller/top.sv", 4, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vtop___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vtop___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vtop___024root___eval_debug_assertions(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_debug_assertions\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY((vlSelfRef.clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelfRef.rst & 0xfeU))) {
        Verilated::overWidthError("rst");}
    if (VL_UNLIKELY((vlSelfRef.start & 0xfeU))) {
        Verilated::overWidthError("start");}
}
#endif  // VL_DEBUG
