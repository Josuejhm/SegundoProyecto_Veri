///////////////////////////////////////////////////////////////////////////////
// File:        md_tx_backpressure_seq.sv
// Description: Secuencia MD TX con backpressure severo. ready_delay sesgado
//              hacia valores altos. Usada para corner cases de FIFO llena.
///////////////////////////////////////////////////////////////////////////////

class md_tx_backpressure_seq extends md_tx_base_seq;
  `uvm_object_utils(md_tx_backpressure_seq)

  int unsigned n_responses = 200;
  int unsigned min_delay   = 5;
  int unsigned max_delay   = 20;

  function new(string name = "md_tx_backpressure_seq");
    super.new(name);
  endfunction

  task body();
    md_tx_seq_item item;
    repeat (n_responses) begin
      item = md_tx_seq_item::type_id::create("md_tx_bp_item");
      start_item(item);
      if (!item.randomize() with {
        ready_delay inside {[min_delay : max_delay]};
      })
        `uvm_fatal("MD_TX_BP_SEQ", "randomize() failed")
      finish_item(item);
    end
  endtask

endclass : md_tx_backpressure_seq
