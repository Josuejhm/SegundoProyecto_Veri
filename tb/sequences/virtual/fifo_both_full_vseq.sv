///////////////////////////////////////////////////////////////////////////////
// File:        fifo_both_full_vseq.sv
// Description: Corner case fifo_both_full.
//              RX rápido + TX casi nunca acepta para llenar ambas FIFOs.
///////////////////////////////////////////////////////////////////////////////

class fifo_both_full_vseq extends uvm_sequence;
  `uvm_object_utils(fifo_both_full_vseq)

  function new(string name = "fifo_both_full_vseq");
    super.new(name);
  endfunction

  task body();
    aligner_vsequencer      vseqr;
    apb_config_ctrl_seq     cfg_seq;
    md_rx_legal_seq         rx_seq;
    md_tx_backpressure_seq  tx_seq;
    apb_rand_seq            apb_seq;

    if (!$cast(vseqr, m_sequencer))
      `uvm_fatal("FIFO_BOTH_FULL_VSEQ", "cast a aligner_vsequencer falló")

    cfg_seq = apb_config_ctrl_seq::type_id::create("cfg_seq");
    cfg_seq.randomize_fields = 1'b0;
    cfg_seq.size   = 3'b001;
    cfg_seq.offset = 2'b00;
    cfg_seq.start(vseqr.apb_seqr);

    fork
      begin
        rx_seq = md_rx_legal_seq::type_id::create("rx_seq");
        rx_seq.n_transfers = 200;
        rx_seq.start(vseqr.md_rx_seqr);
      end
      begin
        tx_seq = md_tx_backpressure_seq::type_id::create("tx_seq");
        tx_seq.n_responses = 300;
        tx_seq.min_delay   = 50;
        tx_seq.max_delay   = 100;
        tx_seq.start(vseqr.md_tx_seqr);
      end
      begin
        apb_seq = apb_rand_seq::type_id::create("apb_seq");
        apb_seq.n_txns = 10;
        apb_seq.start(vseqr.apb_seqr);
      end
    join
  endtask

endclass : fifo_both_full_vseq
