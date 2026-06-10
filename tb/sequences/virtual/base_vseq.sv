///////////////////////////////////////////////////////////////////////////////
// File:        base_vseq.sv
// Description: Virtual sequence base del ambiente cfs_aligner.
//              Coordina los tres agentes simultáneamente:
//                1. Configura CTRL con SIZE/OFFSET legales aleatorios.
//                2. Lanza en paralelo APB rand, MD RX rand y MD TX rand.
//                3. Lee STATUS al final.
///////////////////////////////////////////////////////////////////////////////

class base_vseq extends uvm_sequence;
  `uvm_object_utils(base_vseq)
  `uvm_declare_p_sequencer(aligner_vsequencer)

  // Configurables desde el test
  int unsigned n_apb_txns      = 30;
  int unsigned n_rx_transfers  = 50;
  int unsigned n_tx_responses  = 200; // siempre mayor que RX para no bloquear

  function new(string name = "base_vseq");
    super.new(name);
  endfunction

  task body();
    apb_config_ctrl_seq   cfg_seq;
    apb_rand_seq          apb_seq;
    md_rx_rand_seq        rx_seq;
    md_tx_rand_seq        tx_seq;
    apb_read_status_seq   status_seq;

    // Obtener el virtual sequencer

    // 1. Configurar CTRL con combinación legal aleatoria
    cfg_seq = apb_config_ctrl_seq::type_id::create("cfg_seq");
    cfg_seq.randomize_fields = 1'b1;
    cfg_seq.start(p_sequencer.apb_seqr);

    // 2. Lanzar los tres agentes en paralelo
    fork
      begin : apb_thread
        apb_seq = apb_rand_seq::type_id::create("apb_seq");
        apb_seq.n_txns = n_apb_txns;
        apb_seq.start(p_sequencer.apb_seqr);
      end
      begin : rx_thread
        rx_seq = md_rx_rand_seq::type_id::create("rx_seq");
        rx_seq.n_transfers    = n_rx_transfers;
        rx_seq.illegal_weight = 20;
        rx_seq.start(p_sequencer.md_rx_seqr);
      end
      begin : tx_thread
        tx_seq = md_tx_rand_seq::type_id::create("tx_seq");
        tx_seq.n_responses = n_tx_responses;
        tx_seq.start(p_sequencer.md_tx_seqr);
      end
    join

    // 3. Leer STATUS al final
    status_seq = apb_read_status_seq::type_id::create("status_seq");
    status_seq.start(p_sequencer.apb_seqr);

    `uvm_info("BASE_VSEQ",
      $sformatf("base_vseq completada: CNT_DROP=%0d RX_LVL=%0d TX_LVL=%0d",
                status_seq.cnt_drop, status_seq.rx_lvl, status_seq.tx_lvl),
      UVM_MEDIUM)
  endtask

endclass : base_vseq
