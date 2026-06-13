///////////////////////////////////////////////////////////////////////////////
// File:        aligner_pkg.sv
// Description: Global testbench package for the cfs_aligner UVM environment.
//              Imports uvm_pkg and includes all TB files in dependency order.
//              Parameters must match the elaboration defines set in tb_top.sv.
//
// Usage:       import aligner_pkg::*;  (done once in tb_top.sv)
//
// Note:        If ALGN_DATA_WIDTH or FIFO_DEPTH are changed at elaboration,
//              update the parameter values below to match. A single source of
//              truth avoids width mismatches between the DUT and the TB.
///////////////////////////////////////////////////////////////////////////////

package aligner_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // -------------------------------------------------------------------------
  // Elaboration parameters — must match tb_top.sv defines
  // -------------------------------------------------------------------------
  parameter int unsigned ALGN_DATA_WIDTH   = 32;
  parameter int unsigned FIFO_DEPTH        = 8;

  // Derived — same formula as cfs_aligner localparam
  parameter int unsigned ALGN_OFFSET_WIDTH = (ALGN_DATA_WIDTH <= 8) ? 1
                                           : $clog2(ALGN_DATA_WIDTH / 8);
  parameter int unsigned ALGN_SIZE_WIDTH   = $clog2(ALGN_DATA_WIDTH / 8) + 1;

  // Fixed APB widths
  parameter int unsigned APB_ADDR_WIDTH    = 16;
  parameter int unsigned APB_DATA_WIDTH    = 32;

  // -------------------------------------------------------------------------
  // Register addresses
  // -------------------------------------------------------------------------
  parameter bit [15:0] ADDR_CTRL   = 16'h0000;
  parameter bit [15:0] ADDR_STATUS = 16'h000C;
  parameter bit [15:0] ADDR_IRQEN  = 16'h00F0;
  parameter bit [15:0] ADDR_IRQ    = 16'h00F4;

  // -------------------------------------------------------------------------
  // Reset values
  // -------------------------------------------------------------------------
  // CTRL: SIZE=1 ([2:0]=3'b001), OFFSET=0, CLR=0
  parameter bit [31:0] CTRL_RESET_VAL  = 32'h0000_0001;

  // IRQEN: all five interrupt enable bits set to 1 (bits [4:0])
  parameter bit [31:0] IRQEN_RESET_VAL = 32'h0000_001F;

  // STATUS and IRQ reset to 0
  parameter bit [31:0] STATUS_RESET_VAL = 32'h0000_0000;
  parameter bit [31:0] IRQ_RESET_VAL    = 32'h0000_0000;

  // -------------------------------------------------------------------------
  // CTRL field masks and positions (for scoreboard / sequences)
  // -------------------------------------------------------------------------
  parameter int unsigned CTRL_SIZE_LSB   = 0;
  parameter int unsigned CTRL_SIZE_MSB   = 2;
  parameter int unsigned CTRL_OFFSET_LSB = 8;
  parameter int unsigned CTRL_OFFSET_MSB = 9;
  parameter int unsigned CTRL_CLR_BIT    = 16;

  // -------------------------------------------------------------------------
  // STATUS field positions
  // -------------------------------------------------------------------------
  parameter int unsigned STATUS_CNT_DROP_LSB = 0;
  parameter int unsigned STATUS_CNT_DROP_MSB = 7;
  parameter int unsigned STATUS_RX_LVL_LSB   = 8;
  parameter int unsigned STATUS_RX_LVL_MSB   = 11;
  parameter int unsigned STATUS_TX_LVL_LSB   = 16;
  parameter int unsigned STATUS_TX_LVL_MSB   = 19;

  // -------------------------------------------------------------------------
  // IRQ / IRQEN bit positions
  // -------------------------------------------------------------------------
  parameter int unsigned IRQ_RX_FIFO_EMPTY_BIT = 0;
  parameter int unsigned IRQ_RX_FIFO_FULL_BIT  = 1;
  parameter int unsigned IRQ_TX_FIFO_EMPTY_BIT = 2;
  parameter int unsigned IRQ_TX_FIFO_FULL_BIT  = 3;
  parameter int unsigned IRQ_MAX_DROP_BIT      = 4;

  // -------------------------------------------------------------------------
  // APB timing constraints (from spec / RTL)
  // -------------------------------------------------------------------------
  // Maximum pready wait cycles in Access phase (normal transactions)
  parameter int unsigned APB_MAX_WAIT_CYCLES         = 5;
  // Maximum pready wait cycles for illegal CTRL write (RTL adds 1 extra)
  parameter int unsigned APB_MAX_WAIT_CYCLES_ILLEGAL = 2;

  // -------------------------------------------------------------------------
  // Sequence items
  // -------------------------------------------------------------------------
  `include "seq_items/apb_seq_item.sv"
  `include "seq_items/md_rx_seq_item.sv"
  `include "seq_items/md_tx_seq_item.sv"

  // -------------------------------------------------------------------------
  // APB agent
  // -------------------------------------------------------------------------
  `include "agents/apb/apb_sequencer.sv"
  `include "agents/apb/apb_driver.sv"
  `include "agents/apb/apb_monitor.sv"
  `include "agents/apb/apb_agent.sv"

  // -------------------------------------------------------------------------
  // MD RX agent
  // -------------------------------------------------------------------------
  `include "agents/md_rx/md_rx_sequencer.sv"
  `include "agents/md_rx/md_rx_driver.sv"
  `include "agents/md_rx/md_rx_monitor.sv"
  `include "agents/md_rx/md_rx_agent.sv"

  // -------------------------------------------------------------------------
  // MD TX agent
  // -------------------------------------------------------------------------
  `include "agents/md_tx/md_tx_sequencer.sv"
  `include "agents/md_tx/md_tx_driver.sv"
  `include "agents/md_tx/md_tx_monitor.sv"
  `include "agents/md_tx/md_tx_agent.sv"

  // -------------------------------------------------------------------------
  // APB sequences
  // -------------------------------------------------------------------------
  `include "sequences/apb/apb_base_seq.sv"
  `include "sequences/apb/apb_write_seq.sv"
  `include "sequences/apb/apb_read_seq.sv"
  `include "sequences/apb/apb_config_ctrl_seq.sv"
  `include "sequences/apb/apb_read_status_seq.sv"
  `include "sequences/apb/apb_irq_clear_seq.sv"
  `include "sequences/apb/apb_rand_seq.sv"

  // -------------------------------------------------------------------------
  // MD RX sequences
  // -------------------------------------------------------------------------
  `include "sequences/md_rx/md_rx_base_seq.sv"
  `include "sequences/md_rx/md_rx_legal_seq.sv"
  `include "sequences/md_rx/md_rx_illegal_seq.sv"
  `include "sequences/md_rx/md_rx_rand_seq.sv"

  // -------------------------------------------------------------------------
  // MD TX sequences
  // -------------------------------------------------------------------------
  `include "sequences/md_tx/md_tx_base_seq.sv"
  `include "sequences/md_tx/md_tx_ready_seq.sv"
  `include "sequences/md_tx/md_tx_backpressure_seq.sv"
  `include "sequences/md_tx/md_tx_rand_seq.sv"

  // -------------------------------------------------------------------------
  // Virtual sequencer
  // -------------------------------------------------------------------------

  `include "env/aligner_vsequencer.sv"

  // -------------------------------------------------------------------------
  // Virtual sequences
  // -------------------------------------------------------------------------
  `include "sequences/virtual/base_vseq.sv"
  `include "sequences/virtual/fifo_rx_full_vseq.sv"
  `include "sequences/virtual/fifo_tx_full_vseq.sv"
  `include "sequences/virtual/fifo_both_full_vseq.sv"
  `include "sequences/virtual/fifo_empty_vseq.sv"
  `include "sequences/virtual/illegal_rx_vseq.sv"
  `include "sequences/virtual/cnt_sat_vseq.sv"
  `include "sequences/virtual/apb_unmapped_vseq.sv"
  `include "sequences/virtual/apb_illegal_ctrl_vseq.sv"
  `include "sequences/virtual/irq_stress_vseq.sv"
  `include "sequences/virtual/backpressure_vseq.sv"

  // -------------------------------------------------------------------------
  // Environment components (scoreboard, coverage, env, vsequencer)
  // -------------------------------------------------------------------------
  `include "env/aligner_scoreboard.sv"
  `include "env/aligner_coverage.sv"
  `include "env/aligner_env.sv"

  // -------------------------------------------------------------------------
  // Tests
  // -------------------------------------------------------------------------
  `include "tests/aligner_base_test.sv"
  `include "tests/aligner_fifo_rx_full_test.sv"
  `include "tests/aligner_fifo_tx_full_test.sv"
  `include "tests/aligner_fifo_both_full_test.sv"
  `include "tests/aligner_fifo_empty_test.sv"
  `include "tests/aligner_illegal_rx_test.sv"
  `include "tests/aligner_cnt_sat_test.sv"
  `include "tests/aligner_apb_unmapped_test.sv"
  `include "tests/aligner_apb_illegal_ctrl_test.sv"
  `include "tests/aligner_irq_stress_test.sv"
  `include "tests/aligner_backpressure_test.sv"

endpackage : aligner_pkg