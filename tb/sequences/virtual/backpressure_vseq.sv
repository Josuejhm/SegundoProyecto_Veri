///////////////////////////////////////////////////////////////////////////////
// File:        backpressure_vseq.sv
// Description: Corner case backpressure.
//              Ráfagas largas de backpressure TX para verificar que el DUT
//              mantiene md_tx_valid estable y no pierde datos.
///////////////////////////////////////////////////////////////////////////////

class backpressure_vseq extends uvm_sequence;
  `uvm_object_utils(backpressure_vseq)
  `uvm_declare_p_sequencer(aligner_vsequencer)

  function new(string name = "backpressure_vseq");
    super.new(name);
  endfunction

  task body();
    apb_config_ctrl_seq     cfg_seq;
    md_rx_legal_seq         rx_seq;
    md_tx_backpressure_seq  tx_seq;
    apb_rand_seq            apb_seq;


    // SIZE=4, OFFSET=0: transfers grandes para mayor stress
    cfg_seq = apb_config_ctrl_seq::type_id::create("cfg_seq");
    cfg_seq.randomize_fields = 1'b0;
    cfg_seq.size   = 3'b100; // SIZE=4
    cfg_seq.offset = 2'b00;
    cfg_seq.start(p_sequencer.apb_seqr);

    fork
      begin
        rx_seq = md_rx_legal_seq::type_id::create("rx_seq");
        rx_seq.n_transfers = 100;
        rx_seq.start(p_sequencer.md_rx_seqr);
      end
      begin
        // Ráfagas largas: min 10, max 50 ciclos de backpressure
        tx_seq = md_tx_backpressure_seq::type_id::create("tx_seq");
        tx_seq.n_responses = 200;
        tx_seq.min_delay   = 10;
        tx_seq.max_delay   = 50;
        tx_seq.start(p_sequencer.md_tx_seqr);
      end
      begin
        apb_seq = apb_rand_seq::type_id::create("apb_seq");
        apb_seq.n_txns = 30;
        apb_seq.start(p_sequencer.apb_seqr);
      end
    join
  endtask

endclass : backpressure_vseq
