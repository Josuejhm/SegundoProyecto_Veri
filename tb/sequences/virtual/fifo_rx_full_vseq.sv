///////////////////////////////////////////////////////////////////////////////
// File:        fifo_rx_full_vseq.sv
// Description: Corner case fifo_rx_full.
//              Presiona RX FIFO hasta llenarlo produciendo RX muy rápido
//              y bloqueando TX con backpressure severo.
///////////////////////////////////////////////////////////////////////////////

class fifo_rx_full_vseq extends uvm_sequence;
  `uvm_object_utils(fifo_rx_full_vseq)
  `uvm_declare_p_sequencer(aligner_vsequencer)

  function new(string name = "fifo_rx_full_vseq");
    super.new(name);
  endfunction

  task body();
    apb_config_ctrl_seq     cfg_seq;
    md_rx_legal_seq         rx_seq;
    md_tx_backpressure_seq  tx_seq;
    apb_rand_seq            apb_seq;
    apb_read_status_seq     status_seq;


    // Configurar con SIZE=1, OFFSET=0 para máximo throughput de alineación
    cfg_seq = apb_config_ctrl_seq::type_id::create("cfg_seq");
    cfg_seq.randomize_fields = 1'b0;
    cfg_seq.size   = 3'b001;
    cfg_seq.offset = 2'b00;
    cfg_seq.start(p_sequencer.apb_seqr);

    fork
      begin
        // RX muy rápido: idle_cycles=0 para saturar la FIFO
        rx_seq = md_rx_legal_seq::type_id::create("rx_seq");
        rx_seq.n_transfers = 100;
        rx_seq.start(p_sequencer.md_rx_seqr);
      end
      begin
        // TX muy lento: backpressure severo para que la FIFO se llene
        tx_seq = md_tx_backpressure_seq::type_id::create("tx_seq");
        tx_seq.n_responses = 200;
        tx_seq.min_delay   = 15;
        tx_seq.max_delay   = 30;
        tx_seq.start(p_sequencer.md_tx_seqr);
      end
      begin
        apb_seq = apb_rand_seq::type_id::create("apb_seq");
        apb_seq.n_txns = 20;
        apb_seq.start(p_sequencer.apb_seqr);
      end
    join

    // Verificar que se alcanzó RX FIFO lleno
    status_seq = apb_read_status_seq::type_id::create("status_seq");
    status_seq.start(p_sequencer.apb_seqr);
    `uvm_info("FIFO_RX_FULL_VSEQ",
      $sformatf("Final: RX_LVL=%0d TX_LVL=%0d",
                status_seq.rx_lvl, status_seq.tx_lvl), UVM_MEDIUM)
  endtask

endclass : fifo_rx_full_vseq
