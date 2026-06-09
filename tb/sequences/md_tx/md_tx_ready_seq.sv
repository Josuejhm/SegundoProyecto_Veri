///////////////////////////////////////////////////////////////////////////////
// File:        md_tx_ready_seq.sv
// Description: Secuencia MD TX sin backpressure. ready_delay=0 en todos
//              los items. Usada para el corner case fifo_empty.
///////////////////////////////////////////////////////////////////////////////

class md_tx_ready_seq extends md_tx_base_seq;
  `uvm_object_utils(md_tx_ready_seq)

  int unsigned n_responses = 200;

  function new(string name = "md_tx_ready_seq");
    super.new(name);
  endfunction

  task body();
    md_tx_seq_item item;
    repeat (n_responses) begin
      item = md_tx_seq_item::type_id::create("md_tx_ready_item");
      start_item(item);
      if (!item.randomize() with { ready_delay == 0; })
        `uvm_fatal("MD_TX_READY_SEQ", "randomize() failed")
      finish_item(item);
    end
  endtask

endclass : md_tx_ready_seq
