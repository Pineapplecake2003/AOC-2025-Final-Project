`timescale 1ns/10ps
`include "one_pass_tb.svh"
// Cycle time
`define MAX_CYCLE 100000
`define OPSUM_ADDR q * r * (STRIDE * (e - 1) + FILT_COL) * IFMAP_COL + \
                p * t * q * r * FILT_ROW * FILT_COL + \ 
                p * t *4
`define mem_word(addr) \
  {dut.glb.mem[addr+3], \
  dut.glb.mem[addr+2], \
  dut.glb.mem[addr+1], \
  dut.glb.mem[addr]}

`ifdef SYN
    `timescale 1ns/10ps
    `define CYCLE 10
    `include "Top_syn.v"   // post syn file
    `include "/cad/CBDK/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/VERILOG/N16ADFP_StdCell.v"
`else
    `define CYCLE 10
    `include "Top.sv"
`endif


module Top_tb ;
    logic clk;
    logic rst;

    logic start;

    //
    // ... mapping parameter
    //

    logic done;

    integer i, handler, num, gf, err;
    logic [31:0] GOLDEN [p * t * e * OFMAP_COL];

    initial clk = 1;
    always #`CYCLE clk = ~clk;

    initial rst = 1;
    always #(3/2 * `CYCLE) rst = 0;

    initial begin
        start = 0;
        #(5/2 * `CYCLE) start = 1;
        #(`CYCLE) start = 0;
    end

    // load glb mirror
    initial $readmemh(`GLB_MIRROR_FILE, dut.glb.mem);

    // load gloden
    initial begin
        gf = $fopen(`GOLDEN_FILE, "r");
        if (gf == 0) begin
          $display("\n\n\nError !!! No found \"%s\"\n\n\n",`GOLDEN_FILE);
          $finish;
        end

        num = 0;
        while (!$feof(gf)) begin
          void'($fscanf(gf, "%h\n", GOLDEN[num]));
          num++;
        end
        $fclose(gf);
    end
    
    Top dut(
        .clk(clk),
        .rst(rst),
        // mapping parameters
        // ...
        .start(start),
        .done(done)
    );

    initial begin
        wait(done == 1);
        $display("\nDone\n");
        err = 0;
        for (i = 0; i < num; i++)
        begin
            if (`mem_word(`OPSUM_ADDR + i*4) !== GOLDEN[i])
            begin
                $display("GLB[%5d] = %h, expect = %h", `OPSUM_ADDR + i*4, `mem_word(`OPSUM_ADDR + i*4), GOLDEN[i]);
                err = err + 1;
            end else
            begin
                $display("GLB[%5d] = %h, pass", `OPSUM_ADDR + i*4, `mem_word(`OPSUM_ADDR + i*4));
            end
        end
        if(err)begin
            $display("Failed, %d errors.", err);
        end else begin
            $display("Pass.");
        end
        $display("num: %d\n", num);
        $finish;
    end

    initial begin
        $display("Ttimeout.");
        #(`MAX_CYCLE * `CYCLE) $finish;
    end
    
    initial begin
    `ifdef FSDB
        $fsdbDumpfile("./wave/one_pass_tb.fsdb");
        $fsdbDumpvars("+struct", "+mda", dut);
    `endif
    end
endmodule