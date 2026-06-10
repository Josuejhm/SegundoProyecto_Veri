///////////////////////////////////////////////////////////////////////////////
// File:        apb_illegal_ctrl_vseq.sv
// Description: Corner case apb_illegal_ctrl.
//              Escribe CTRL con combinaciones ilegales (SIZE=0 y combos
//              inválidos de OFFSET/SIZE). Verifica pslverr=1 en cada caso.
//              Luego escribe una combinación legal y verifica pslverr=0.
///////////////////////////////////////////////////////////////////////////////

class apb_illegal_ctrl_vseq extends uvm_sequence;
  `uvm_object_utils(apb_illegal_ctrl_vseq)
  `uvm_declare_p_sequencer(aligner_vsequencer)

  function new(string name = "apb_illegal_ctrl_vseq");
    super.new(name);
  endfunction

  task body();
    apb_config_ctrl_seq cfg_seq;
    apb_write_seq       wr_seq;
    md_rx_rand_seq      rx_seq;
    md_tx_rand_seq      tx_seq;
    bit [31:0] wdata;
    bit [2:0]  s;
    bit [1:0]  o;


    // Arrancar RX y TX en background
    fork
      begin
        rx_seq = md_rx_rand_seq::type_id::create("rx_seq");
        rx_seq.n_transfers    = 80;
        rx_seq.illegal_weight = 0;
        rx_seq.start(p_sequencer.md_rx_seqr);
      end
      begin
        tx_seq = md_tx_rand_seq::type_id::create("tx_seq");
        tx_seq.n_responses = 200;
        tx_seq.start(p_sequencer.md_tx_seqr);
      end
    join_none

    // Caso 1: SIZE=0 (siempre ilegal)
    repeat (5) begin
      wdata = '0;
      wdata[2:0] = 3'b000; // SIZE=0
      wdata[9:8] = $urandom_range(0, 3);
      wr_seq = apb_write_seq::type_id::create("wr_seq_size0");
      wr_seq.addr = aligner_pkg::ADDR_CTRL;
      wr_seq.data = wdata;
      wr_seq.start(p_sequencer.apb_seqr);
      if (!wr_seq.slverr)
        `uvm_error("APB_ILLEGAL_CTRL_VSEQ",
          "pslverr=0 para CTRL write con SIZE=0 — se esperaba error")
    end

    // Caso 2: combinaciones ilegales ((ALGN_DATA_WIDTH/8)+OFFSET) % SIZE != 0
    repeat (10) begin
      // Generar combinación ilegal aleatoria (size!=0 pero combo inválido)
      if (!std::randomize(s, o) with {
        s != 3'b000;
        ((aligner_pkg::ALGN_DATA_WIDTH / 8) + o) % s != 0;
        o < (aligner_pkg::ALGN_DATA_WIDTH / 8);
      }) begin
        // Si no se puede randomizar (p.ej. DATA_WIDTH=8 tiene pocas opciones)
        `uvm_info("APB_ILLEGAL_CTRL_VSEQ",
          "No se encontró combo ilegal para este ALGN_DATA_WIDTH — skip",
          UVM_MEDIUM)
        continue;
      end
      wdata = '0;
      wdata[2:0] = s;
      wdata[9:8] = o;
      wr_seq = apb_write_seq::type_id::create("wr_seq_illegal_combo");
      wr_seq.addr = aligner_pkg::ADDR_CTRL;
      wr_seq.data = wdata;
      wr_seq.start(p_sequencer.apb_seqr);
      if (!wr_seq.slverr)
        `uvm_error("APB_ILLEGAL_CTRL_VSEQ",
          $sformatf("pslverr=0 para CTRL write ilegal SIZE=%0d OFFSET=%0d", s, o))
    end

    // Caso 3: write legal — verificar pslverr=0 y que CTRL se actualiza
    cfg_seq = apb_config_ctrl_seq::type_id::create("cfg_seq_legal");
    cfg_seq.randomize_fields = 1'b1;
    cfg_seq.start(p_sequencer.apb_seqr);

    disable fork;
  endtask

endclass : apb_illegal_ctrl_vseq
