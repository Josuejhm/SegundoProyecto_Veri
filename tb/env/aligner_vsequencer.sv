///////////////////////////////////////////////////////////////////////////////
// Archivo:     aligner_vsequencer.sv
// Descripción: Virtual sequencer para el ambiente de UVM del cfs_aligner.
//              No contiene lógica propia — expone handles a los tres
//              sequencers concretos para que las virtual sequences los usen
//              directamente.
//
//              Los handles se asignan en connect_phase de aligner_env.
///////////////////////////////////////////////////////////////////////////////

class aligner_vsequencer extends uvm_sequencer;
  `uvm_component_utils(aligner_vsequencer)

  // Handles a sequencers concretos — asignados por el env en connect_phase
  apb_sequencer   apb_seqr;
  md_rx_sequencer md_rx_seqr;
  md_tx_sequencer md_tx_seqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : aligner_vsequencer