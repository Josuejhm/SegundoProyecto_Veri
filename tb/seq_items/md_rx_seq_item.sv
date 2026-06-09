///////////////////////////////////////////////////////////////////////////////
// File:        md_rx_seq_item.sv
// Description: Sequence item para el agente MD RX.
//
//              Campos rand: data, offset, size, idle_cycles
//              Campos no-rand (capturados por monitor): err_captured
//
//              Constraints:
//                legal_c   — activo por defecto. Genera (offset,size) legales.
//                illegal_c — inactivo por defecto. Para corner case illegal_rx.
//
//              Para generar transfers ilegales desde una secuencia:
//                item.legal_c.constraint_mode(0);
//                item.illegal_c.constraint_mode(1);
///////////////////////////////////////////////////////////////////////////////

class md_rx_seq_item extends uvm_sequence_item;
  `uvm_object_utils(md_rx_seq_item)

  // -------------------------------------------------------------------------
  // Campos rand — controlados por el driver
  // -------------------------------------------------------------------------
  rand bit [aligner_pkg::ALGN_DATA_WIDTH-1:0]   data;
  rand bit [aligner_pkg::ALGN_OFFSET_WIDTH-1:0] offset;
  rand bit [aligner_pkg::ALGN_SIZE_WIDTH-1:0]   size;
  rand int unsigned                              idle_cycles;

  // -------------------------------------------------------------------------
  // Campos no-rand — capturados por el monitor en el handshake
  // -------------------------------------------------------------------------
  bit err_captured; // valor de md_rx_err observado cuando valid & ready

  // -------------------------------------------------------------------------
  // Constraints
  // -------------------------------------------------------------------------

  // Activo por defecto: genera (offset, size) legales
  constraint legal_c {
    size != 0;
    ((aligner_pkg::ALGN_DATA_WIDTH / 8) + offset) % size == 0;
    offset < (aligner_pkg::ALGN_DATA_WIDTH / 8);
  }

  // Inactivo por defecto: para corner case illegal_rx
  constraint illegal_c {
    (size == 0) ||
    (((aligner_pkg::ALGN_DATA_WIDTH / 8) + offset) % size != 0);
  }

  // Delays sesgados hacia bajo para no ralentizar la simulación
  constraint idle_c {
    idle_cycles dist { 0 := 60, [1:3] := 30, [4:8] := 10 };
  }

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------
  function new(string name = "md_rx_seq_item");
    super.new(name);
    illegal_c.constraint_mode(0); // inactivo por defecto
  endfunction

  // -------------------------------------------------------------------------
  // do_copy
  // -------------------------------------------------------------------------
  function void do_copy(uvm_object rhs);
    md_rx_seq_item rhs_;
    if (!$cast(rhs_, rhs))
      `uvm_fatal("MD_RX_ITEM", "do_copy: cast failed")
    super.do_copy(rhs);
    data         = rhs_.data;
    offset       = rhs_.offset;
    size         = rhs_.size;
    idle_cycles  = rhs_.idle_cycles;
    err_captured = rhs_.err_captured;
  endfunction

  // -------------------------------------------------------------------------
  // do_compare
  // -------------------------------------------------------------------------
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    md_rx_seq_item rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (super.do_compare(rhs, comparer) &&
            data         === rhs_.data        &&
            offset       === rhs_.offset      &&
            size         === rhs_.size        &&
            err_captured === rhs_.err_captured);
  endfunction

  // -------------------------------------------------------------------------
  // convert2string
  // -------------------------------------------------------------------------
  function string convert2string();
    return $sformatf(
      "MD_RX data=0x%0h offset=%0d size=%0d idle=%0d err=%0b",
      data, offset, size, idle_cycles, err_captured
    );
  endfunction

endclass : md_rx_seq_item
