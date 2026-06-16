///////////////////////////////////////////////////////////////////////////////
// File:        md_tx_backpressure_seq.sv
// Description: Secuencia MD TX con backpressure configurable.
//              Cuando min_delay y max_delay son 0, usa el constraint del
//              item (distribución normal). Cuando se especifica un rango
//              via plusargs, desactiva ready_delay_c para evitar conflicto.
//
//              stop_after_current: cuando base_vseq lo activa (drain_tx=1),
//              la secuencia termina limpiamente al final de la iteración
//              actual en lugar de ser abortada por disable fork.
///////////////////////////////////////////////////////////////////////////////

class md_tx_backpressure_seq extends md_tx_base_seq;
  `uvm_object_utils(md_tx_backpressure_seq)

  int unsigned n_responses       = 200;
  int unsigned min_delay         = 0;
  int unsigned max_delay         = 3;
  bit          stop_after_current = 1'b0; // activado por base_vseq tras el drain

  function new(string name = "md_tx_backpressure_seq");
    super.new(name);
  endfunction

  task body();
    md_tx_seq_item item;
    int unsigned i = 0;
    while (i < n_responses && !stop_after_current) begin
      item = md_tx_seq_item::type_id::create("md_tx_bp_item");
      start_item(item);
      item.ready_delay_c.constraint_mode(0);
      if (!item.randomize() with {
        ready_delay inside {[min_delay : max_delay]};
      })
        `uvm_fatal("MD_TX_BP_SEQ", "randomize() failed")
      finish_item(item);
      i++;
    end
  endtask

endclass : md_tx_backpressure_seq
