///////////////////////////////////////////////////////////////////////////////
// Archivo:        apb_agent.sv
// Descripción: Agente APB para el ambiente UVM cfs_aligner.
//              Siempre activo (UVM_ACTIVE) — instancia sequencer, driver
//              y monitor. Expone apb_mon_ap al env para conexión con
//              scoreboard y coverage collector.
///////////////////////////////////////////////////////////////////////////////

class apb_agent extends uvm_agent;
  `uvm_component_utils(apb_agent)

  // Sub-componentes
  apb_sequencer  sequencer;
  apb_driver     driver;
  apb_monitor    monitor;

  // Analysis port — re-expuesto desde el monitor hacia el env
  uvm_analysis_port #(apb_seq_item) apb_mon_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // build_phase
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_mon_ap = new("apb_mon_ap", this);
    sequencer  = apb_sequencer::type_id::create("sequencer", this);
    driver     = apb_driver::type_id::create("driver",     this);
    monitor    = apb_monitor::type_id::create("monitor",   this);
  endfunction

  // -------------------------------------------------------------------------
  // connect_phase — conectar driver al sequencer y re-exponer el apb del monitor
  // -------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
    monitor.apb_mon_ap.connect(apb_mon_ap);
  endfunction

endclass : apb_agent