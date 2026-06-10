///////////////////////////////////////////////////////////////////////////////
// File:        cnt_sat_vseq.sv
// Description: Corner case cnt_sat.
//              Satura CNT_DROP hasta MAX (255), verifica que no wrappea,
//              luego limpia con CLR y verifica reset a 0.
///////////////////////////////////////////////////////////////////////////////

class cnt_sat_vseq extends uvm_sequence;
  `uvm_object_utils(cnt_sat_vseq)
  `uvm_declare_p_sequencer(aligner_vsequencer)

  function new(string name = "cnt_sat_vseq");
    super.new(name);
  endfunction

  task body();
    apb_config_ctrl_seq  cfg_seq;
    md_rx_illegal_seq    rx_seq;
    md_tx_rand_seq       tx_seq;
    apb_read_status_seq  status_seq;
    bit [31:0] wdata;
    bit        slverr;


    // Configurar DUT
    cfg_seq = apb_config_ctrl_seq::type_id::create("cfg_seq");
    cfg_seq.randomize_fields = 1'b0;
    cfg_seq.size   = 3'b001;
    cfg_seq.offset = 2'b00;
    cfg_seq.start(p_sequencer.apb_seqr);

    // Arrancar TX en background para no bloquear RX
    fork
      begin
        tx_seq = md_tx_rand_seq::type_id::create("tx_seq");
        tx_seq.n_responses = 500;
        tx_seq.start(p_sequencer.md_tx_seqr);
      end
    join_none

    // Fase 1: enviar ~250 transfers ilegales para acercar CNT_DROP a MAX
    rx_seq = md_rx_illegal_seq::type_id::create("rx_seq1");
    rx_seq.n_transfers = 250;
    rx_seq.start(p_sequencer.md_rx_seqr);

    // Verificar CNT_DROP
    status_seq = apb_read_status_seq::type_id::create("status_seq1");
    status_seq.start(p_sequencer.apb_seqr);
    `uvm_info("CNT_SAT_VSEQ",
      $sformatf("Tras 250 ilegales: CNT_DROP=%0d", status_seq.cnt_drop),
      UVM_MEDIUM)

    // Fase 2: enviar 10 más — verificar que CNT_DROP no supera 255
    rx_seq = md_rx_illegal_seq::type_id::create("rx_seq2");
    rx_seq.n_transfers = 10;
    rx_seq.start(p_sequencer.md_rx_seqr);

    status_seq = apb_read_status_seq::type_id::create("status_seq2");
    status_seq.start(p_sequencer.apb_seqr);
    if (status_seq.cnt_drop > 8'hFF)
      `uvm_error("CNT_SAT_VSEQ", "CNT_DROP wrapeó — debe saturar en 255")
    else
      `uvm_info("CNT_SAT_VSEQ",
        $sformatf("CNT_DROP=%0d (no wrapeó)", status_seq.cnt_drop), UVM_MEDIUM)

    // Fase 3: limpiar CNT_DROP con CLR=1
    cfg_seq = apb_config_ctrl_seq::type_id::create("cfg_clr");
    cfg_seq.randomize_fields = 1'b0;
    cfg_seq.size   = 3'b001;
    cfg_seq.offset = 2'b00;
    cfg_seq.clr    = 1'b1;
    cfg_seq.start(p_sequencer.apb_seqr);

    // Verificar que CNT_DROP volvió a 0
    status_seq = apb_read_status_seq::type_id::create("status_seq3");
    status_seq.start(p_sequencer.apb_seqr);
    if (status_seq.cnt_drop != 0)
      `uvm_error("CNT_SAT_VSEQ",
        $sformatf("CNT_DROP=%0d tras CLR=1 — se esperaba 0", status_seq.cnt_drop))
    else
      `uvm_info("CNT_SAT_VSEQ", "CNT_DROP=0 tras CLR — correcto", UVM_MEDIUM)

    disable fork;
  endtask

endclass : cnt_sat_vseq
