///////////////////////////////////////////////////////////////////////////////
// File:        md_tx_sequencer.sv
// Description: Sequencer para el agente MD TX.
///////////////////////////////////////////////////////////////////////////////

class md_tx_sequencer extends uvm_sequencer #(md_tx_seq_item);
  `uvm_component_utils(md_tx_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : md_tx_sequencer
