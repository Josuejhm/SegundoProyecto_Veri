///////////////////////////////////////////////////////////////////////////////
// File:        apb_if.sv
// Description: APB interface for the cfs_aligner UVM environment.
//              Widths match the cfs_aligner wrapper localparam values:
//                APB_ADDR_WIDTH = 16
//                APB_DATA_WIDTH = 32
//
//              Contains:
//                - driver_cb   : clocking block used by the APB driver
//                - monitor_cb  : clocking block used by the APB monitor
//              The irq signal is NOT part of this interface; it is exposed as
//              a loose signal in tb_top (tb_top.irq) and observed directly
//              by the APB monitor through hierarchical reference.
///////////////////////////////////////////////////////////////////////////////

interface apb_if (
  input logic clk,
  input logic reset_n
);

  // -------------------------------------------------------------------------
  // Signal declarations
  // -------------------------------------------------------------------------
  // Master → Slave (driven by the APB driver)
  logic [15:0] paddr;
  logic        pwrite;
  logic        psel;
  logic        penable;
  logic [31:0] pwdata;

  // Slave → Master (driven by the DUT)
  logic        pready;
  logic [31:0] prdata;
  logic        pslverr;

  // -------------------------------------------------------------------------
  // Driver clocking block
  // -------------------------------------------------------------------------
  clocking driver_cb @(posedge clk);
    default output #1;   // drive 1ns after posedge (setup margin)

    output paddr;
    output pwrite;
    output psel;
    output penable;
    output pwdata;

    input  pready;
    input  prdata;
    input  pslverr;
  endclocking

  // -------------------------------------------------------------------------
  // Monitor clocking block
  // -------------------------------------------------------------------------
  clocking monitor_cb @(posedge clk);
    default input #1;    // sample 1ns after posedge (hold margin)

    input paddr;
    input pwrite;
    input psel;
    input penable;
    input pwdata;
    input pready;
    input prdata;
    input pslverr;
  endclocking

  // -------------------------------------------------------------------------
  // Modport definitions
  // -------------------------------------------------------------------------
  modport driver_mp  (clocking driver_cb,  input clk, input reset_n);
  modport monitor_mp (clocking monitor_cb, input clk, input reset_n);

endinterface : apb_if