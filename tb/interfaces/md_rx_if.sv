///////////////////////////////////////////////////////////////////////////////
// File:        md_rx_if.sv
// Description: MD RX interface for the cfs_aligner UVM environment.
//
//              The DUT is the SLAVE on this interface:
//                - Driver (TB) sends:   md_rx_valid, md_rx_data,
//                                       md_rx_offset, md_rx_size
//                - DUT responds with:   md_rx_ready, md_rx_err
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

interface md_rx_if (
  input logic clk,
  input logic reset_n
);

  import aligner_pkg::*;

  // -------------------------------------------------------------------------
  // Signal declarations
  // -------------------------------------------------------------------------
  // TB → DUT (driven by the MD RX driver)
  logic                              md_rx_valid;
  logic [ALGN_DATA_WIDTH-1:0]        md_rx_data;
  logic [ALGN_OFFSET_WIDTH-1:0]      md_rx_offset;
  logic [ALGN_SIZE_WIDTH-1:0]        md_rx_size;

  // DUT → TB (driven by the DUT)
  logic                              md_rx_ready;
  logic                              md_rx_err;

  // -------------------------------------------------------------------------
  // Driver clocking block
  // -------------------------------------------------------------------------
  clocking driver_cb @(posedge clk);
    default output #1;

    output md_rx_valid;
    output md_rx_data;
    output md_rx_offset;
    output md_rx_size;

    input  md_rx_ready;
    input  md_rx_err;
  endclocking

  // -------------------------------------------------------------------------
  // Monitor clocking block
  // -------------------------------------------------------------------------
  clocking monitor_cb @(posedge clk);
    default input #1;

    input md_rx_valid;
    input md_rx_data;
    input md_rx_offset;
    input md_rx_size;
    input md_rx_ready;
    input md_rx_err;
  endclocking

  // -------------------------------------------------------------------------
  // Modport definitions
  // -------------------------------------------------------------------------
  modport driver_mp  (clocking driver_cb,  input clk);
  modport monitor_mp (clocking monitor_cb, input clk);

endinterface : md_rx_if