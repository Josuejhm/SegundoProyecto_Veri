///////////////////////////////////////////////////////////////////////////////
// Archivo:        tb_top.sv
// Descripción: Top-level testbench module para el ambiente cfs_aligner.
//              Gernera el clock y reset, instancia el DUT y las tres
//              interfaces (APB, MD RX, MD TX), las registra en
//              uvm_config_db y llama run_test().
//
// Parámetro de configuración:
//   ALGN_DATA_WIDTH : 8 | 16 | 32 (default) | 64
//   FIFO_DEPTH      : 2 | 8 (default) | 16
///////////////////////////////////////////////////////////////////////////////


// Importa UVM y el testbench package
import uvm_pkg::*;
`include "uvm_macros.svh"

module tb_top;

  // -------------------------------------------------------------------------
  // Parámetros:
  //   Simulación +define+ALGN_DATA_WIDTH=64 +define+FIFO_DEPTH=16
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
  // Clock y reset
  // -------------------------------------------------------------------------
  localparam real CLK_PERIOD_NS = 10.0; // 100 MHz

  logic clk;
  logic reset_n;
  logic irq;        // Señal de interrupción (salta del DUT al testbench)

  // Generación del clock
  initial clk = 1'b0;
  always #(CLK_PERIOD_NS / 2.0) clk = ~clk;

  // Reset: activo en bajo
  initial begin
    reset_n = 1'b0;
    repeat (20) @(posedge clk);
    @(negedge clk);   
    reset_n = 1'b1;
  end

  // -------------------------------------------------------------------------
  // Instanciación de interfaces virtuales
  // -------------------------------------------------------------------------
  apb_if   apb_if_inst  (.clk(clk), .reset_n(reset_n));
  md_rx_if md_rx_if_inst(.clk(clk), .reset_n(reset_n));
  md_tx_if md_tx_if_inst(.clk(clk), .reset_n(reset_n));

  // -------------------------------------------------------------------------
  // Instanciación del DUT
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

    // MD RX (DUT es esclavo — recibe datos)
    .md_rx_valid  (md_rx_if_inst.md_rx_valid),
    .md_rx_data   (md_rx_if_inst.md_rx_data),
    .md_rx_offset (md_rx_if_inst.md_rx_offset),
    .md_rx_size   (md_rx_if_inst.md_rx_size),
    .md_rx_ready  (md_rx_if_inst.md_rx_ready),
    .md_rx_err    (md_rx_if_inst.md_rx_err),

    // MD TX (DUT es maestro — envía datos alineados)
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
  // UVM config_db — registra las interfaces virtuales
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
  // Waveform
  // -------------------------------------------------------------------------
  initial begin
`ifdef DUMP_VCD
    $dumpfile("results/waves.vcd");
    $dumpvars(0, tb_top);
`else
    $fsdbDumpfile("results/waves.fsdb");
    $fsdbDumpvars(0, tb_top);
    $fsdbDumpMDA(); 
`endif
  end

  // -------------------------------------------------------------------------
  // Correr la prueba
  // -------------------------------------------------------------------------
  initial begin
    run_test();
  end

endmodule