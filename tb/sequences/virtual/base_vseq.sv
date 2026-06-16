///////////////////////////////////////////////////////////////////////////////
// File:        base_vseq.sv
// Description: Virtual sequence base del ambiente cfs_aligner.
//              Coordina los tres agentes simultáneamente:
//                1. Configura CTRL con SIZE/OFFSET (fijos o aleatorios).
//                2. Lanza en paralelo APB rand, MD RX rand y MD TX rand.
//                3. Lee STATUS al final.
//
//              Todos los parámetros son configurables via plusargs:
//                +n_rx_transfers   : número de transfers RX        (default 50)
//                +n_tx_responses   : número de responses TX        (default 200)
//                +n_apb_txns       : número de transacciones APB   (default 30)
//                +rx_illegal_weight: % de transfers ilegales RX    (default 20)
//                +tx_min_delay     : delay mínimo backpressure TX  (default 0)
//                +tx_max_delay     : delay máximo backpressure TX  (default 3)
//                +unmapped_only    : solo accesos APB no mapeados  (default 0)
//                +ctrl_randomize   : randomizar SIZE/OFFSET        (default 1)
//                +ctrl_size        : SIZE fijo (si randomize=0)    (default 1)
//                +ctrl_offset      : OFFSET fijo (si randomize=0)  (default 0)
//                +drain_tx         : esperar TX FIFO vacía al final (default 1)
//                +poll_timeout     : máx lecturas de STATUS en drain (default 500)
//
//              Lógica de terminación:
//                - Si drain_tx=1: TX corre indefinidamente en background;
//                  la simulación termina cuando APB+RX completan Y el drain
//                  confirma TX FIFO vacía. Esto garantiza que el scoreboard
//                  reciba todos los transfers independientemente de WIDTH/DEPTH.
//                - Si drain_tx=0: termina cuando TX agota n_tx_responses o
//                  cuando APB+RX completan (join_any), lo que ocurra primero.
///////////////////////////////////////////////////////////////////////////////

class base_vseq extends uvm_sequence;
  `uvm_object_utils(base_vseq)
  `uvm_declare_p_sequencer(aligner_vsequencer)

  // Parámetros con defaults — sobreescritos por plusargs en body()
  int unsigned n_rx_transfers    = 50;
  int unsigned n_tx_responses    = 200;
  int unsigned n_apb_txns        = 30;
  int unsigned rx_illegal_weight = 20;
  int unsigned tx_min_delay      = 0;
  int unsigned tx_max_delay      = 3;
  bit          unmapped_only     = 1'b0;
  bit          ctrl_randomize    = 1'b1;
  int unsigned ctrl_size         = 1;
  int unsigned ctrl_offset       = 0;
  bit          drain_tx          = 1'b1;
  int unsigned poll_timeout      = 500;

  function new(string name = "base_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  // read_plusargs — leer todos los plusargs y sobreescribir defaults
  // -------------------------------------------------------------------------
  function void read_plusargs();
    int unsigned tmp;
    if ($value$plusargs("n_rx_transfers=%0d",    tmp)) n_rx_transfers    = tmp;
    if ($value$plusargs("n_tx_responses=%0d",    tmp)) n_tx_responses    = tmp;
    if ($value$plusargs("n_apb_txns=%0d",        tmp)) n_apb_txns        = tmp;
    if ($value$plusargs("rx_illegal_weight=%0d", tmp)) rx_illegal_weight = tmp;
    if ($value$plusargs("tx_min_delay=%0d",      tmp)) tx_min_delay      = tmp;
    if ($value$plusargs("tx_max_delay=%0d",      tmp)) tx_max_delay      = tmp;
    if ($value$plusargs("unmapped_only=%0d",     tmp)) unmapped_only     = tmp[0];
    if ($value$plusargs("ctrl_randomize=%0d",    tmp)) ctrl_randomize    = tmp[0];
    if ($value$plusargs("ctrl_size=%0d",         tmp)) ctrl_size         = tmp;
    if ($value$plusargs("ctrl_offset=%0d",       tmp)) ctrl_offset       = tmp;
    if ($value$plusargs("drain_tx=%0d",          tmp)) drain_tx          = tmp[0];
    if ($value$plusargs("poll_timeout=%0d",      tmp)) poll_timeout      = tmp;

    `uvm_info("BASE_VSEQ", $sformatf(
      "Parámetros: n_rx=%0d n_tx=%0d n_apb=%0d illegal_w=%0d tx_dly=[%0d:%0d] unmapped=%0b ctrl_rand=%0b size=%0d offset=%0d",
      n_rx_transfers, n_tx_responses, n_apb_txns, rx_illegal_weight,
      tx_min_delay, tx_max_delay, unmapped_only, ctrl_randomize,
      ctrl_size, ctrl_offset), UVM_MEDIUM)
  endfunction

  task body();
    apb_config_ctrl_seq   cfg_seq;
    apb_rand_seq          apb_seq;
    md_rx_rand_seq        rx_seq;
    md_tx_backpressure_seq tx_seq;
    apb_read_status_seq   drain_seq;
    apb_read_status_seq   status_seq;

    // Leer plusargs antes de arrancar
    read_plusargs();

    // 1. Configurar CTRL
    cfg_seq = apb_config_ctrl_seq::type_id::create("cfg_seq");
    cfg_seq.randomize_fields = ctrl_randomize;
    if (!ctrl_randomize) begin
      cfg_seq.size   = ctrl_size[2:0];
      cfg_seq.offset = ctrl_offset[1:0];
    end
    cfg_seq.start(p_sequencer.apb_seqr);

    // 2. Lanzar TX en background; APB y RX corren hasta completar
    tx_seq = md_tx_backpressure_seq::type_id::create("tx_seq");
    tx_seq.min_delay   = tx_min_delay;
    tx_seq.max_delay   = tx_max_delay;

    if (drain_tx) begin
      // Con drain_tx=1: TX corre indefinidamente (n_responses muy grande)
      // y el join_any termina cuando el drain confirma TX FIFO vacía.
      // Esto garantiza que el scoreboard reciba todos los transfers
      // independientemente de WIDTH/DEPTH.
      tx_seq.n_responses = 32'h7FFF_FFFF;

      fork
        tx_seq.start(p_sequencer.md_tx_seqr);

        begin
          fork
            begin : apb_thread
              apb_seq = apb_rand_seq::type_id::create("apb_seq");
              apb_seq.n_txns        = n_apb_txns;
              apb_seq.unmapped_only = unmapped_only;
              apb_seq.start(p_sequencer.apb_seqr);
            end
            begin : rx_thread
              rx_seq = md_rx_rand_seq::type_id::create("rx_seq");
              rx_seq.n_transfers    = n_rx_transfers;
              rx_seq.illegal_weight = rx_illegal_weight;
              rx_seq.start(p_sequencer.md_rx_seqr);
            end
          join

          // Drain: esperar TX FIFO vacía — controla el fin del fork
          drain_seq = apb_read_status_seq::type_id::create("drain_seq");
          drain_seq.poll_en       = 1'b1;
          drain_seq.poll_tx_empty = 1'b1;
          drain_seq.poll_timeout  = poll_timeout;
          drain_seq.start(p_sequencer.apb_seqr);

          // Marcar TX para que termine limpiamente en su próxima iteración
          tx_seq.stop_after_current = 1'b1;
        end
      join_any
      // Esperar a que TX termine su transacción actual antes de continuar
      // Esto evita que el monitor pierda la última transacción
      #100ns;
      disable fork;

    end else begin
      // Con drain_tx=0: TX corre en background; APB+RX controlan el fin.
      // Se usa stop_sequences() en lugar de disable fork para evitar
      // el deadlock SEQREQZMB cuando TX tiene un request pendiente.
      tx_seq.n_responses = n_tx_responses;

      fork : tx_fork_nd
        tx_seq.start(p_sequencer.md_tx_seqr);
      join_none

      fork
        begin : apb_thread_nd
          apb_seq = apb_rand_seq::type_id::create("apb_seq");
          apb_seq.n_txns        = n_apb_txns;
          apb_seq.unmapped_only = unmapped_only;
          apb_seq.start(p_sequencer.apb_seqr);
        end
        begin : rx_thread_nd
          rx_seq = md_rx_rand_seq::type_id::create("rx_seq");
          rx_seq.n_transfers    = n_rx_transfers;
          rx_seq.illegal_weight = rx_illegal_weight;
          rx_seq.start(p_sequencer.md_rx_seqr);
        end
      join

      // Detener TX limpiamente — stop_sequences espera a que la transacción
      // actual termine antes de sacar la secuencia del sequencer
      p_sequencer.md_tx_seqr.stop_sequences();
      #50ns; // margen para que el monitor procese el último handshake
    end

    // 3. Leer STATUS al final
    status_seq = apb_read_status_seq::type_id::create("status_seq");
    status_seq.start(p_sequencer.apb_seqr);

    `uvm_info("BASE_VSEQ",
      $sformatf("base_vseq completada: CNT_DROP=%0d RX_LVL=%0d TX_LVL=%0d",
                status_seq.cnt_drop, status_seq.rx_lvl, status_seq.tx_lvl),
      UVM_MEDIUM)
  endtask

endclass : base_vseq
