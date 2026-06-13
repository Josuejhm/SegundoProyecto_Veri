///////////////////////////////////////////////////////////////////////////////
// File:        md_tx_if.sv
// Description: MD TX interface for the cfs_aligner UVM environment.
//
//              The DUT is the MASTER on this interface:
//                - DUT sends:       md_tx_valid, md_tx_data,
//                                   md_tx_offset, md_tx_size
//                - Driver (TB) responds with: md_tx_ready, md_tx_err
//
//              Signal widths depend on ALGN_DATA_WIDTH (set via aligner_pkg
//              parameters). The interface uses the package parameters directly.
//
//              MD protocol reminder (from RTL header):
//                - Transfer starts when valid = 1
//                - Transfer ends  when valid = 1 AND ready = 1
//                - Once valid is asserted, data/offset/size must stay stable
//                  until the handshake completes
//                - err is only valid at the end of the transfer (ready = 1)
///////////////////////////////////////////////////////////////////////////////

import aligner_pkg::*;

interface md_tx_if (
  input logic clk
  input logic reset_n
);

  // -------------------------------------------------------------------------
  // Signal declarations
  // -------------------------------------------------------------------------
  // DUT → TB (driven by the DUT)
  logic                              md_tx_valid;
  logic [ALGN_DATA_WIDTH-1:0]        md_tx_data;
  logic [ALGN_OFFSET_WIDTH-1:0]      md_tx_offset;
  logic [ALGN_SIZE_WIDTH-1:0]        md_tx_size;

  // TB → DUT (driven by the MD TX driver)
  logic                              md_tx_ready;
  logic                              md_tx_err;

  // -------------------------------------------------------------------------
  // Driver clocking block
  // -------------------------------------------------------------------------
  clocking driver_cb @(posedge clk);
    default output #1;

    output md_tx_ready;
    output md_tx_err;

    input  md_tx_valid;
    input  md_tx_data;
    input  md_tx_offset;
    input  md_tx_size;
  endclocking

  // -------------------------------------------------------------------------
  // Monitor clocking block
  // -------------------------------------------------------------------------
  clocking monitor_cb @(posedge clk);
    default input #1;

    input md_tx_valid;
    input md_tx_data;
    input md_tx_offset;
    input md_tx_size;
    input md_tx_ready;
    input md_tx_err;
  endclocking

  // -------------------------------------------------------------------------
  // Modport definitions
  // -------------------------------------------------------------------------
  modport driver_mp  (clocking driver_cb,  input clk);
  modport monitor_mp (clocking monitor_cb, input clk);

endinterface : md_tx_if