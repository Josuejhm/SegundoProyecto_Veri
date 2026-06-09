///////////////////////////////////////////////////////////////////////////////
// File:        md_rx_illegal_seq.sv
// Description: Secuencia MD RX que genera solo transfers con (offset, size)
//              ilegales. Activa illegal_c y desactiva legal_c.
//              Usada para el corner case illegal_rx y cnt_sat.
///////////////////////////////////////////////////////////////////////////////

class md_rx_illegal_seq extends md_rx_base_seq;
  `uvm_object_utils(md_rx_illegal_seq)

  int unsigned n_transfers = 20;

  function new(string name = "md_rx_illegal_seq");
    super.new(name);
  endfunction

  task body();
    md_rx_seq_item item;
    repeat (n_transfers) begin
      item = md_rx_seq_item::type_id::create("md_rx_illegal_item");
      start_item(item);
      item.legal_c.constraint_mode(0);
      item.illegal_c.constraint_mode(1);
      if (!item.randomize())
        `uvm_fatal("MD_RX_ILLEGAL_SEQ", "randomize() failed")
      finish_item(item);
    end
  endtask

endclass : md_rx_illegal_seq
