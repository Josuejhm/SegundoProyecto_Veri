///////////////////////////////////////////////////////////////////////////////
// File:        apb_unmapped_vseq.sv
// Description: Corner case apb_unmapped.
//              Accesos APB a direcciones no mapeadas — todos deben
//              responder con pslverr=1.
///////////////////////////////////////////////////////////////////////////////

class apb_unmapped_vseq extends uvm_sequence;
  `uvm_object_utils(apb_unmapped_vseq)

  function new(string name = "apb_unmapped_vseq");
    super.new(name);
  endfunction

  task body();
    aligner_vsequencer   vseqr;
    apb_config_ctrl_seq  cfg_seq;
    apb_rand_seq         apb_seq;
    md_rx_rand_seq       rx_seq;
    md_tx_rand_seq       tx_seq;

    if (!$cast(vseqr, m_sequencer))
      `uvm_fatal("APB_UNMAPPED_VSEQ", "cast a aligner_vsequencer falló")

    // Configurar el DUT primero con acceso mapeado
    cfg_seq = apb_config_ctrl_seq::type_id::create("cfg_seq");
    cfg_seq.randomize_fields = 1'b1;
    cfg_seq.start(vseqr.apb_seqr);

    fork
      begin
        // Accesos solo a direcciones no mapeadas
        apb_seq = apb_rand_seq::type_id::create("apb_seq");
        apb_seq.n_txns        = 50;
        apb_seq.unmapped_only = 1'b1;
        apb_seq.start(vseqr.apb_seqr);
      end
      begin
        rx_seq = md_rx_rand_seq::type_id::create("rx_seq");
        rx_seq.n_transfers    = 40;
        rx_seq.illegal_weight = 0;
        rx_seq.start(vseqr.md_rx_seqr);
      end
      begin
        tx_seq = md_tx_rand_seq::type_id::create("tx_seq");
        tx_seq.n_responses = 200;
        tx_seq.start(vseqr.md_tx_seqr);
      end
    join
  endtask

endclass : apb_unmapped_vseq
