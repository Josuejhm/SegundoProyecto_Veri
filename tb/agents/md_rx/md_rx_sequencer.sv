///////////////////////////////////////////////////////////////////////////////
// File:        md_rx_sequencer.sv
// Description: Sequencer para el agente MD RX.
//              Sin lógica adicional — uvm_sequencer parametrizado con
//              md_rx_seq_item es suficiente para este protocolo.
///////////////////////////////////////////////////////////////////////////////

class md_rx_sequencer extends uvm_sequencer #(md_rx_seq_item);
  `uvm_component_utils(md_rx_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : md_rx_sequencer
