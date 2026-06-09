///////////////////////////////////////////////////////////////////////////////
// File:        md_rx_base_seq.sv
// Description: Clase base para todas las secuencias MD RX.
//              Proporciona el helper send() para enviar un item ya
//              configurado. Las subclases implementan body().
///////////////////////////////////////////////////////////////////////////////

class md_rx_base_seq extends uvm_sequence #(md_rx_seq_item);
  `uvm_object_utils(md_rx_base_seq)

  function new(string name = "md_rx_base_seq");
    super.new(name);
  endfunction

  virtual task body();
  endtask

  // -------------------------------------------------------------------------
  // send — helper para enviar un md_rx_seq_item ya construido
  // -------------------------------------------------------------------------
  task send(md_rx_seq_item item);
    start_item(item);
    if (!item.randomize())
      `uvm_fatal("MD_RX_BASE_SEQ", "randomize() failed en send()")
    finish_item(item);
  endtask

endclass : md_rx_base_seq
