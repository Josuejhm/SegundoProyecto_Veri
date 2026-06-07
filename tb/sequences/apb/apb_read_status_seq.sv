///////////////////////////////////////////////////////////////////////////////
// File:        apb_read_status_seq.sv
// Description: APB sequence que lee el registro STATUS y expone los campos
//              CNT_DROP, RX_LVL y TX_LVL al llamador.
//
//              Opcionalmente hace polling hasta que una condición se cumpla
//              (útil para esperar que la FIFO llegue a cierto nivel antes
//              de continuar con la virtual sequence).
//
//              Uso típico — lectura simple:
//                apb_read_status_seq seq;
//                seq = apb_read_status_seq::type_id::create("seq");
//                seq.start(env.vseqr.apb_seqr);
//                $display("RX_LVL=%0d", seq.rx_lvl);
//
//              Uso típico — polling:
//                seq.poll_en       = 1;
//                seq.poll_rx_full  = 1;   // esperar RX FIFO lleno
//                seq.poll_timeout  = 500; // máximo 500 lecturas
//                seq.start(env.vseqr.apb_seqr);
///////////////////////////////////////////////////////////////////////////////

class apb_read_status_seq extends apb_base_seq;
  `uvm_object_utils(apb_read_status_seq)

  // Opciones de polling
  bit          poll_en      = 1'b0;  // habilitar modo polling
  bit          poll_rx_full = 1'b0;  // esperar RX_LVL == FIFO_DEPTH
  bit          poll_tx_full = 1'b0;  // esperar TX_LVL == FIFO_DEPTH
  bit          poll_rx_empty= 1'b0;  // esperar RX_LVL == 0
  bit          poll_tx_empty= 1'b0;  // esperar TX_LVL == 0
  int unsigned poll_timeout = 1000;  // máximo de lecturas antes de error
  int unsigned idle         = 0;

  // Campos capturados al final (última lectura)
  bit [31:0] raw;
  bit [7:0]  cnt_drop;
  bit [3:0]  rx_lvl;
  bit [3:0]  tx_lvl;
  bit        slverr;

  function new(string name = "apb_read_status_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] rdata;
    bit        serr;
    int unsigned count = 0;

    do begin
      read(aligner_pkg::ADDR_STATUS, rdata, serr, idle);

      // Parsear campos
      cnt_drop = rdata[aligner_pkg::STATUS_CNT_DROP_MSB : aligner_pkg::STATUS_CNT_DROP_LSB];
      rx_lvl   = rdata[aligner_pkg::STATUS_RX_LVL_MSB  : aligner_pkg::STATUS_RX_LVL_LSB];
      tx_lvl   = rdata[aligner_pkg::STATUS_TX_LVL_MSB  : aligner_pkg::STATUS_TX_LVL_LSB];
      raw      = rdata;
      slverr   = serr;

      if (serr)
        `uvm_error("APB_STATUS_SEQ", "pslverr=1 inesperado en lectura de STATUS")

      count++;
      if (count >= poll_timeout) begin
        `uvm_error("APB_STATUS_SEQ",
          $sformatf("Polling timeout tras %0d lecturas: RX_LVL=%0d TX_LVL=%0d CNT_DROP=%0d",
                    count, rx_lvl, tx_lvl, cnt_drop))
        break;
      end

    end while (poll_en && !poll_condition_met());

    `uvm_info("APB_STATUS_SEQ",
      $sformatf("STATUS: CNT_DROP=%0d RX_LVL=%0d TX_LVL=%0d",
                cnt_drop, rx_lvl, tx_lvl), UVM_HIGH)
  endtask

  // -------------------------------------------------------------------------
  // poll_condition_met — devuelve 1 cuando la condición de polling se cumple
  // -------------------------------------------------------------------------
  function bit poll_condition_met();
    if (poll_rx_full  && rx_lvl != aligner_pkg::FIFO_DEPTH) return 1'b0;
    if (poll_tx_full  && tx_lvl != aligner_pkg::FIFO_DEPTH) return 1'b0;
    if (poll_rx_empty && rx_lvl != 0)                       return 1'b0;
    if (poll_tx_empty && tx_lvl != 0)                       return 1'b0;
    return 1'b1;
  endfunction

endclass : apb_read_status_seq