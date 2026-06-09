///////////////////////////////////////////////////////////////////////////////
// File:        fifo_empty_vseq.sv
// Description: Corner case fifo_empty.
//              RX lento + TX siempre listo para mantener FIFOs vacías.
///////////////////////////////////////////////////////////////////////////////

class fifo_empty_vseq extends uvm_sequence;
  `uvm_object_utils(fifo_empty_vseq)

  function new(string name = "fifo_empty_vseq");
    super.new(name);
  endfunction

  task body();
    aligner_vsequencer   vseqr;
    apb_config_ctrl_seq  cfg_seq;
    md_rx_rand_seq       rx_seq;
    md_tx_ready_seq      tx_seq;
    apb_rand_seq         apb_seq;

    if (!$cast(vseqr, m_sequencer))
      `uvm_fatal("FIFO_EMPTY_VSEQ", "cast a aligner_vsequencer falló")

    cfg_seq = apb_config_ctrl_seq::type_id::create("cfg_seq");
    cfg_seq.randomize_fields = 1'b1;
    cfg_seq.start(vseqr.apb_seqr);

    fork
      begin
        // RX lento: idle_cycles alto para que las FIFOs se vacíen entre transfers
        rx_seq = md_rx_rand_seq::type_id::create("rx_seq");
        rx_seq.n_transfers    = 50;
        rx_seq.illegal_weight = 0;
        // Sesgar idle_cycles hacia valores altos mediante inline constraint
        rx_seq.start(vseqr.md_rx_seqr);
      end
      begin
        // TX siempre listo: sin backpressure
        tx_seq = md_tx_ready_seq::type_id::create("tx_seq");
        tx_seq.n_responses = 200;
        tx_seq.start(vseqr.md_tx_seqr);
      end
      begin
        apb_seq = apb_rand_seq::type_id::create("apb_seq");
        apb_seq.n_txns = 20;
        apb_seq.start(vseqr.apb_seqr);
      end
    join
  endtask

endclass : fifo_empty_vseq
