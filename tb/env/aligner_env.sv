///////////////////////////////////////////////////////////////////////////////
// File:        aligner_env.sv
// Description: Top-level UVM environment for the cfs_aligner verification.
//
//              build_phase  : crea los tres agentes (ACTIVE), el virtual
//                             sequencer, el scoreboard y el coverage collector.
//
//              connect_phase: conecta los seis analysis ports:
//                apb_agent.apb_mon_ap       → scoreboard.apb_export
//                apb_agent.apb_mon_ap       → coverage_collector.apb_export
//                md_rx_agent.md_rx_mon_ap   → scoreboard.md_rx_export
//                md_rx_agent.md_rx_mon_ap   → coverage_collector.md_rx_export
//                md_tx_agent.md_tx_mon_ap   → scoreboard.md_tx_export
//                md_tx_agent.md_tx_mon_ap   → coverage_collector.md_tx_export
//
//              Asigna handles de sequencers al virtual sequencer.
///////////////////////////////////////////////////////////////////////////////

class aligner_env extends uvm_env;
  `uvm_component_utils(aligner_env)

  // -------------------------------------------------------------------------
  // Component handles
  // -------------------------------------------------------------------------
  apb_agent              apb_agt;
  md_rx_agent            md_rx_agt;
  md_tx_agent            md_tx_agt;

  aligner_vsequencer     vseqr;
  aligner_scoreboard     scoreboard;
  aligner_coverage       coverage_collector;

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // build_phase — crea todos los componentes hijos
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    apb_agt    = apb_agent::type_id::create("apb_agt",    this);
    md_rx_agt  = md_rx_agent::type_id::create("md_rx_agt", this);
    md_tx_agt  = md_tx_agent::type_id::create("md_tx_agt", this);

    vseqr            = aligner_vsequencer::type_id::create("vseqr",            this);
    scoreboard       = aligner_scoreboard::type_id::create("scoreboard",       this);
    coverage_collector = aligner_coverage::type_id::create("coverage_collector", this);
  endfunction

  // -------------------------------------------------------------------------
  // connect_phase — conecta analysis ports y asigna handles al vseqr
  // -------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    // APB monitor → scoreboard + coverage
    apb_agt.apb_mon_ap.connect(scoreboard.apb_export);
    apb_agt.apb_mon_ap.connect(coverage_collector.apb_export);

    // MD RX monitor → scoreboard + coverage
    md_rx_agt.md_rx_mon_ap.connect(scoreboard.md_rx_export);
    md_rx_agt.md_rx_mon_ap.connect(coverage_collector.md_rx_export);

    // MD TX monitor → scoreboard + coverage
    md_tx_agt.md_tx_mon_ap.connect(scoreboard.md_tx_export);
    md_tx_agt.md_tx_mon_ap.connect(coverage_collector.md_tx_export);

    // Virtual sequencer — asignar handles de sequencers concretos
    vseqr.apb_seqr    = apb_agt.sequencer;
    vseqr.md_rx_seqr  = md_rx_agt.sequencer;
    vseqr.md_tx_seqr  = md_tx_agt.sequencer;
  endfunction

endclass : aligner_env