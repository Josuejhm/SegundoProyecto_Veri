///////////////////////////////////////////////////////////////////////////////
// File:        md_rx_agent.sv
// Description: Agente MD RX para el ambiente cfs_aligner.
//              Siempre activo (UVM_ACTIVE) — instancia sequencer, driver
//              y monitor. Expone md_rx_mon_ap al env para conexión con
//              scoreboard y coverage collector.
///////////////////////////////////////////////////////////////////////////////

class md_rx_agent extends uvm_agent;
  `uvm_component_utils(md_rx_agent)

  md_rx_sequencer sequencer;
  md_rx_driver    driver;
  md_rx_monitor   monitor;

  // Analysis port re-expuesto desde el monitor hacia el env
  uvm_analysis_port #(md_rx_seq_item) md_rx_mon_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // build_phase
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    md_rx_mon_ap = new("md_rx_mon_ap", this);
    sequencer    = md_rx_sequencer::type_id::create("sequencer", this);
    driver       = md_rx_driver::type_id::create("driver",     this);
    monitor      = md_rx_monitor::type_id::create("monitor",   this);
  endfunction

  // -------------------------------------------------------------------------
  // connect_phase
  // -------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
    monitor.md_rx_mon_ap.connect(md_rx_mon_ap);
  endfunction

endclass : md_rx_agent
