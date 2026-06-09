///////////////////////////////////////////////////////////////////////////////
// File:        md_tx_seq_item.sv
// Description: Sequence item para el agente MD TX.
//
//              El agente MD TX actúa como receptor (esclavo) del stream
//              alineado que el DUT genera.
//
//              Campos rand: ready_delay, err
//              Campos no-rand (capturados por monitor): data, offset, size
///////////////////////////////////////////////////////////////////////////////

class md_tx_seq_item extends uvm_sequence_item;
  `uvm_object_utils(md_tx_seq_item)

  // -------------------------------------------------------------------------
  // Campos rand — controlados por el driver
  // -------------------------------------------------------------------------
  rand int unsigned ready_delay; // ciclos con md_tx_ready=0 antes de aceptar
  rand bit          err;         // md_tx_err durante el handshake

  // -------------------------------------------------------------------------
  // Campos no-rand — capturados por el monitor cuando valid & ready
  // -------------------------------------------------------------------------
  bit [aligner_pkg::ALGN_DATA_WIDTH-1:0]   data;
  bit [aligner_pkg::ALGN_OFFSET_WIDTH-1:0] offset;
  bit [aligner_pkg::ALGN_SIZE_WIDTH-1:0]   size;

  // -------------------------------------------------------------------------
  // Constraints
  // -------------------------------------------------------------------------

  // Backpressure bajo por defecto
  constraint ready_delay_c {
    ready_delay dist { 0 := 60, [1:3] := 30, [4:10] := 10 };
  }

  // err con baja probabilidad — el DUT no reacciona a él internamente
  constraint err_c {
    err dist { 0 := 90, 1 := 10 };
  }

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------
  function new(string name = "md_tx_seq_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  // do_copy
  // -------------------------------------------------------------------------
  function void do_copy(uvm_object rhs);
    md_tx_seq_item rhs_;
    if (!$cast(rhs_, rhs))
      `uvm_fatal("MD_TX_ITEM", "do_copy: cast failed")
    super.do_copy(rhs);
    ready_delay = rhs_.ready_delay;
    err         = rhs_.err;
    data        = rhs_.data;
    offset      = rhs_.offset;
    size        = rhs_.size;
  endfunction

  // -------------------------------------------------------------------------
  // do_compare
  // -------------------------------------------------------------------------
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    md_tx_seq_item rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (super.do_compare(rhs, comparer) &&
            data   === rhs_.data            &&
            offset === rhs_.offset          &&
            size   === rhs_.size);
  endfunction

  // -------------------------------------------------------------------------
  // convert2string
  // -------------------------------------------------------------------------
  function string convert2string();
    return $sformatf(
      "MD_TX data=0x%0h offset=%0d size=%0d ready_delay=%0d err=%0b",
      data, offset, size, ready_delay, err
    );
  endfunction

endclass : md_tx_seq_item
