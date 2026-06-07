///////////////////////////////////////////////////////////////////////////////
// File:        apb_sequencer.sv
// Description: Sequencer for the APB agent.
//              No custom logic required — uvm_sequencer parameterized with
//              apb_seq_item is sufficient for this protocol.
///////////////////////////////////////////////////////////////////////////////

class apb_sequencer extends uvm_sequencer #(apb_seq_item);
  `uvm_component_utils(apb_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : apb_sequencer