// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtop.h for the primary calling header

#ifndef VERILATED_VTOP___024ROOT_H_
#define VERILATED_VTOP___024ROOT_H_  // guard

#include "verilated.h"


class Vtop__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtop___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    VL_IN8(start,0,0);
    VL_OUT8(done,0,0);
    VL_OUT8(notify_host,0,0);
    CData/*2:0*/ top__DOT__dma_inst__DOT__cs;
    CData/*2:0*/ top__DOT__dma_inst__DOT__ns;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__rst__0;
    CData/*0:0*/ __VactContinue;
    VL_IN16(length,15,0);
    VL_OUT16(mem_length,15,0);
    SData/*15:0*/ top__DOT__dma_inst__DOT__counter;
    SData/*15:0*/ top__DOT__dma_inst__DOT__len;
    VL_IN(src_addr,31,0);
    VL_IN(dst_addr,31,0);
    VL_OUT(mem_read_addr,31,0);
    VL_IN(mem_read_data,31,0);
    VL_IN(glb_r_addr,31,0);
    VL_OUT(glb_dout,31,0);
    IData/*31:0*/ top__DOT__dma_inst__DOT__read_ptr;
    IData/*31:0*/ top__DOT__dma_inst__DOT__write_ptr;
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<CData/*7:0*/, 65536> top__DOT__glb_inst__DOT__mem;
    VlUnpacked<CData/*0:0*/, 2> __Vm_traceActivity;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<2> __VactTriggered;
    VlTriggerVec<2> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtop__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtop___024root(Vtop__Syms* symsp, const char* v__name);
    ~Vtop___024root();
    VL_UNCOPYABLE(Vtop___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
