///////////////////////////////////////////////////////////////////////////////
// File:        illegal_rx_vseq.sv
// Description: Corner case illegal_rx.
//              Alta probabilidad de (offset,size) ilegales en RX para
//              saturar CNT_DROP.
///////////////////////////////////////////////////////////////////////////////

class illegal_rx_vseq extends uvm_sequence;
  `uvm_object_utils(illegal_rx_vseq)
  `uvm_declare_p_sequencer(aligner_vsequencer)

  function new(string name = "illegal_rx_vseq");
    super.new(name);
  endfunction

  task body();
    apb_config_ctrl_seq  cfg_seq;
    md_rx_illegal_seq    rx_seq;
    md_tx_rand_seq       tx_seq;
    apb_rand_seq         apb_seq;
    apb_read_status_seq  status_seq;


    cfg_seq = apb_config_ctrl_seq::type_id::create("cfg_seq");
    cfg_seq.randomize_fields = 1'b0;
    cfg_seq.size   = 3'b001;
    cfg_seq.offset = 2'b00;
    cfg_seq.start(p_sequencer.apb_seqr);

    fork
      begin
        rx_seq = md_rx_illegal_seq::type_id::create("rx_seq");
        rx_seq.n_transfers = 150;
        rx_seq.start(p_sequencer.md_rx_seqr);
      end
      begin
        tx_seq = md_tx_rand_seq::type_id::create("tx_seq");
        tx_seq.n_responses = 200;
        tx_seq.start(p_sequencer.md_tx_seqr);
      end
      begin
        apb_seq = apb_rand_seq::type_id::create("apb_seq");
        apb_seq.n_txns = 20;
        apb_seq.start(p_sequencer.apb_seqr);
      end
    join

    status_seq = apb_read_status_seq::type_id::create("status_seq");
    status_seq.start(p_sequencer.apb_seqr);
    if (status_seq.cnt_drop == 0)
      `uvm_error("ILLEGAL_RX_VSEQ",
        "CNT_DROP=0 tras enviar transfers ilegales — inesperado")
    else
      `uvm_info("ILLEGAL_RX_VSEQ",
        $sformatf("CNT_DROP=%0d tras transfers ilegales", status_seq.cnt_drop),
        UVM_MEDIUM)
  endtask

endclass : illegal_rx_vseq
