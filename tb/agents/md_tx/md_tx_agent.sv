///////////////////////////////////////////////////////////////////////////////
// File:        md_tx_agent.sv
// Description: Agente MD TX para el ambiente cfs_aligner.
//              Siempre activo (UVM_ACTIVE). Expone md_tx_mon_ap al env.
///////////////////////////////////////////////////////////////////////////////

class md_tx_agent extends uvm_agent;
  `uvm_component_utils(md_tx_agent)

  md_tx_sequencer sequencer;
  md_tx_driver    driver;
  md_tx_monitor   monitor;

  uvm_analysis_port #(md_tx_seq_item) md_tx_mon_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // build_phase
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    md_tx_mon_ap = new("md_tx_mon_ap", this);
    sequencer    = md_tx_sequencer::type_id::create("sequencer", this);
    driver       = md_tx_driver::type_id::create("driver",     this);
    monitor      = md_tx_monitor::type_id::create("monitor",   this);
  endfunction

  // -------------------------------------------------------------------------
  // connect_phase
  // -------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
    monitor.md_tx_mon_ap.connect(md_tx_mon_ap);
  endfunction

endclass : md_tx_agent
