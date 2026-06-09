///////////////////////////////////////////////////////////////////////////////
// File:        md_tx_base_seq.sv
// Description: Clase base para todas las secuencias MD TX.
///////////////////////////////////////////////////////////////////////////////

class md_tx_base_seq extends uvm_sequence #(md_tx_seq_item);
  `uvm_object_utils(md_tx_base_seq)

  function new(string name = "md_tx_base_seq");
    super.new(name);
  endfunction

  virtual task body();
  endtask

endclass : md_tx_base_seq
