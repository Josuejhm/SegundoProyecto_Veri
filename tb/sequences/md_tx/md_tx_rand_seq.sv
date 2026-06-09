///////////////////////////////////////////////////////////////////////////////
// File:        md_tx_rand_seq.sv
// Description: Secuencia MD TX con backpressure aleatorio usando los
//              constraints por defecto del item.
///////////////////////////////////////////////////////////////////////////////

class md_tx_rand_seq extends md_tx_base_seq;
  `uvm_object_utils(md_tx_rand_seq)

  int unsigned n_responses = 200;

  function new(string name = "md_tx_rand_seq");
    super.new(name);
  endfunction

  task body();
    md_tx_seq_item item;
    repeat (n_responses) begin
      item = md_tx_seq_item::type_id::create("md_tx_rand_item");
      start_item(item);
      if (!item.randomize())
        `uvm_fatal("MD_TX_RAND_SEQ", "randomize() failed")
      finish_item(item);
    end
  endtask

endclass : md_tx_rand_seq
