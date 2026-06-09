///////////////////////////////////////////////////////////////////////////////
// File:        md_rx_legal_seq.sv
// Description: Secuencia MD RX que genera solo transfers con (offset, size)
//              legales. El constraint legal_c está activo por defecto en
//              md_rx_seq_item; aquí se asegura explícitamente.
///////////////////////////////////////////////////////////////////////////////

class md_rx_legal_seq extends md_rx_base_seq;
  `uvm_object_utils(md_rx_legal_seq)

  int unsigned n_transfers = 20;

  function new(string name = "md_rx_legal_seq");
    super.new(name);
  endfunction

  task body();
    md_rx_seq_item item;
    repeat (n_transfers) begin
      item = md_rx_seq_item::type_id::create("md_rx_legal_item");
      start_item(item);
      // Asegurar legal_c activo e illegal_c inactivo
      item.legal_c.constraint_mode(1);
      item.illegal_c.constraint_mode(0);
      if (!item.randomize())
        `uvm_fatal("MD_RX_LEGAL_SEQ", "randomize() failed")
      finish_item(item);
    end
  endtask

endclass : md_rx_legal_seq
