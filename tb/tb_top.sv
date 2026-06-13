///////////////////////////////////////////////////////////////////////////////
// File:        tb_top.sv
// Description: Top-level testbench module for cfs_aligner UVM environment.
//              Generates clock and reset, instantiates the DUT and the three
//              interfaces (APB, MD RX, MD TX), registers them in
//              uvm_config_db and calls run_test().
//
// Parameters (set at elaboration time):
//   ALGN_DATA_WIDTH : 8 | 16 | 32 (default) | 64
//   FIFO_DEPTH      : 2 | 8 (default) | 16
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

// Import UVM and the testbench package (includes all TB classes)
import uvm_pkg::*;
`include "uvm_macros.svh"

module tb_top;

  // -------------------------------------------------------------------------
  // Parameters — override at elaboration:
  //   simulation ... +define+ALGN_DATA_WIDTH=64 +define+FIFO_DEPTH=16
  // -------------------------------------------------------------------------
`ifdef ALGN_DATA_WIDTH
  localparam int unsigned DUT_DATA_WIDTH = `ALGN_DATA_WIDTH;
`else
  localparam int unsigned DUT_DATA_WIDTH = 32;
`endif

`ifdef FIFO_DEPTH
  localparam int unsigned DUT_FIFO_DEPTH = `FIFO_DEPTH;
`else
  localparam int unsigned DUT_FIFO_DEPTH = 8;
`endif

  // -------------------------------------------------------------------------
  // Clock and reset
  // -------------------------------------------------------------------------
  localparam real CLK_PERIOD_NS = 10.0; // 100 MHz

  logic clk;
  logic reset_n;
  logic irq;        // DUT interrupt output — observed via tb_top.irq hierarchy

  // Clock generation
  initial clk = 1'b0;
  always #(CLK_PERIOD_NS / 2.0) clk = ~clk;

  // Reset: active-low, asserted for the first 20 cycles
  initial begin
    reset_n = 1'b0;
    repeat (20) @(posedge clk);
    @(negedge clk);   // deassert on negedge to avoid setup violations
    reset_n = 1'b1;
  end

  // -------------------------------------------------------------------------
  // Interface instantiation (all share the same clk — CDC disabled in DUT)
  // -------------------------------------------------------------------------
  apb_if   apb_if_inst  (.clk(clk), .reset_n(reset_n));
  md_rx_if md_rx_if_inst(.clk(clk));
  md_tx_if md_tx_if_inst(.clk(clk));

  // -------------------------------------------------------------------------
  // DUT instantiation
  // -------------------------------------------------------------------------
  cfs_aligner #(
    .ALGN_DATA_WIDTH (DUT_DATA_WIDTH),
    .FIFO_DEPTH      (DUT_FIFO_DEPTH)
  ) dut (
    .clk          (clk),
    .reset_n      (reset_n),

    // APB slave
    .paddr        (apb_if_inst.paddr),
    .pwrite       (apb_if_inst.pwrite),
    .psel         (apb_if_inst.psel),
    .penable      (apb_if_inst.penable),
    .pwdata       (apb_if_inst.pwdata),
    .pready       (apb_if_inst.pready),
    .prdata       (apb_if_inst.prdata),
    .pslverr      (apb_if_inst.pslverr),

    // MD RX (DUT is slave — receives data)
    .md_rx_valid  (md_rx_if_inst.md_rx_valid),
    .md_rx_data   (md_rx_if_inst.md_rx_data),
    .md_rx_offset (md_rx_if_inst.md_rx_offset),
    .md_rx_size   (md_rx_if_inst.md_rx_size),
    .md_rx_ready  (md_rx_if_inst.md_rx_ready),
    .md_rx_err    (md_rx_if_inst.md_rx_err),

    // MD TX (DUT is master — sends aligned data)
    .md_tx_valid  (md_tx_if_inst.md_tx_valid),
    .md_tx_data   (md_tx_if_inst.md_tx_data),
    .md_tx_offset (md_tx_if_inst.md_tx_offset),
    .md_tx_size   (md_tx_if_inst.md_tx_size),
    .md_tx_ready  (md_tx_if_inst.md_tx_ready),
    .md_tx_err    (md_tx_if_inst.md_tx_err),

    // Interrupt — señal suelta, accesible por jerarquía como tb_top.irq
    .irq          (irq)
  );

  // -------------------------------------------------------------------------
  // UVM config_db — register virtual interfaces
  // -------------------------------------------------------------------------
  initial begin
    uvm_config_db #(virtual apb_if)::set(
      null, "uvm_test_top.*", "apb_vif", apb_if_inst);

    uvm_config_db #(virtual md_rx_if)::set(
      null, "uvm_test_top.*", "md_rx_vif", md_rx_if_inst);

    uvm_config_db #(virtual md_tx_if)::set(
      null, "uvm_test_top.*", "md_tx_vif", md_tx_if_inst);
  end

  // -------------------------------------------------------------------------
  // Waveform dump
  // -------------------------------------------------------------------------
  initial begin
`ifdef DUMP_VCD
    $dumpfile("results/waves.vcd");
    $dumpvars(0, tb_top);
`else
    // FSDB (Verdi/DVE) — default
    $fsdbDumpfile("results/waves.fsdb");
    $fsdbDumpvars(0, tb_top);
    $fsdbDumpMDA(); // dump multi-dimensional arrays
`endif
  end

  // -------------------------------------------------------------------------
  // Kick off UVM test
  // -------------------------------------------------------------------------
  initial begin
    run_test();
  end

endmodule