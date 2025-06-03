// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vtop__Syms.h"


void Vtop___024root__trace_chg_0_sub_0(Vtop___024root* vlSelf, VerilatedVcd::Buffer* bufp);

void Vtop___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_chg_0\n"); );
    // Init
    Vtop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtop___024root*>(voidSelf);
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vtop___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vtop___024root__trace_chg_0_sub_0(Vtop___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_chg_0_sub_0\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    if (VL_UNLIKELY(vlSelfRef.__Vm_traceActivity[1U])) {
        bufp->chgIData(oldp+0,(vlSelfRef.top__DOT__dma_inst__DOT__write_ptr),32);
        bufp->chgBit(oldp+1,((3U == (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))));
        bufp->chgCData(oldp+2,(vlSelfRef.top__DOT__dma_inst__DOT__cs),3);
        bufp->chgSData(oldp+3,(vlSelfRef.top__DOT__dma_inst__DOT__counter),16);
        bufp->chgSData(oldp+4,(vlSelfRef.top__DOT__dma_inst__DOT__len),16);
        bufp->chgIData(oldp+5,(vlSelfRef.top__DOT__dma_inst__DOT__read_ptr),32);
    }
    bufp->chgBit(oldp+6,(vlSelfRef.clk));
    bufp->chgBit(oldp+7,(vlSelfRef.rst));
    bufp->chgBit(oldp+8,(vlSelfRef.start));
    bufp->chgIData(oldp+9,(vlSelfRef.src_addr),32);
    bufp->chgIData(oldp+10,(vlSelfRef.dst_addr),32);
    bufp->chgSData(oldp+11,(vlSelfRef.length),16);
    bufp->chgBit(oldp+12,(vlSelfRef.done));
    bufp->chgBit(oldp+13,(vlSelfRef.notify_host));
    bufp->chgIData(oldp+14,(vlSelfRef.mem_read_addr),32);
    bufp->chgIData(oldp+15,(vlSelfRef.mem_read_data),32);
    bufp->chgSData(oldp+16,(vlSelfRef.mem_length),16);
    bufp->chgIData(oldp+17,(vlSelfRef.glb_r_addr),32);
    bufp->chgIData(oldp+18,(vlSelfRef.glb_dout),32);
    bufp->chgCData(oldp+19,(((4U & (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))
                              ? 0U : ((2U & (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))
                                       ? ((1U & (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))
                                           ? (((IData)(vlSelfRef.top__DOT__dma_inst__DOT__counter) 
                                               == ((IData)(vlSelfRef.top__DOT__dma_inst__DOT__len) 
                                                   - (IData)(1U)))
                                               ? 4U
                                               : 2U)
                                           : 3U) : 
                                      ((1U & (IData)(vlSelfRef.top__DOT__dma_inst__DOT__cs))
                                        ? 2U : ((IData)(vlSelfRef.start)
                                                 ? 1U
                                                 : 0U))))),3);
}

void Vtop___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_cleanup\n"); );
    // Init
    Vtop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtop___024root*>(voidSelf);
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    vlSymsp->__Vm_activity = false;
    vlSymsp->TOP.__Vm_traceActivity[0U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[1U] = 0U;
}
