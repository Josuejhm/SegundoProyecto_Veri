///////////////////////////////////////////////////////////////////////////////
// File:        apb_seq_item.sv
// Description: Sequence item for the APB agent.
//
//              Campos rand: addr, write, wdata, idle_cycles
//              Campos no-rand (capturados por el monitor): rdata, slverr
//
//              Constraints notables:
//                - addr_mapped_c   : restringe addr a las cuatro direcciones
//                                    mapeadas del DUT (deshabilitable).
//                - addr_unmapped_c : restringe addr a direcciones NO mapeadas
//                                    (deshabilitable, para corner case APB unmapped).
//                - idle_cycles_c   : distribución sesgada hacia valores bajos.
//
//              Uso típico:
//                item.addr_mapped_c.constraint_mode(0);   // deshabilitar mapped
//                item.addr_unmapped_c.constraint_mode(1); // habilitar unmapped
///////////////////////////////////////////////////////////////////////////////

class apb_seq_item extends uvm_sequence_item;
  `uvm_object_utils(apb_seq_item)

  // -------------------------------------------------------------------------
  // Rand fields — controlados por el driver
  // -------------------------------------------------------------------------
  rand bit [15:0]      addr;
  rand bit             write;       // 1 = write, 0 = read
  rand bit [31:0]      wdata;
  rand int unsigned    idle_cycles; // ciclos en IDLE antes de la transacción

  // -------------------------------------------------------------------------
  // Non-rand fields — capturados por el monitor al final de la transacción
  // -------------------------------------------------------------------------
  bit [31:0]  rdata;    // prdata capturado cuando pready=1 (solo reads)
  bit         slverr;   // pslverr capturado cuando pready=1

  // -------------------------------------------------------------------------
  // Constraints
  // -------------------------------------------------------------------------

  // Por defecto: solo accesos a direcciones mapeadas
  constraint addr_mapped_c {
    addr inside {
      aligner_pkg::ADDR_CTRL,
      aligner_pkg::ADDR_STATUS,
      aligner_pkg::ADDR_IRQEN,
      aligner_pkg::ADDR_IRQ
    };
  }

  // Corner case unmapped — deshabilitar addr_mapped_c y habilitar este
  constraint addr_unmapped_c {
    !(addr inside {
      aligner_pkg::ADDR_CTRL,
      aligner_pkg::ADDR_STATUS,
      aligner_pkg::ADDR_IRQEN,
      aligner_pkg::ADDR_IRQ
    });
  }

  // idle_cycles: sesgado hacia valores bajos para no ralentizar la simulación
  constraint idle_cycles_c {
    idle_cycles dist { 0 := 50, [1:3] := 40, [4:8] := 10 };
  }

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------
  function new(string name = "apb_seq_item");
    super.new(name);
    addr_unmapped_c.constraint_mode(0); // inactivo por defecto
  endfunction

  // -------------------------------------------------------------------------
  // do_copy
  // -------------------------------------------------------------------------
  function void do_copy(uvm_object rhs);
    apb_seq_item rhs_;
    if (!$cast(rhs_, rhs))
      `uvm_fatal("APB_SEQ_ITEM", "do_copy: cast failed")
    super.do_copy(rhs);
    addr        = rhs_.addr;
    write       = rhs_.write;
    wdata       = rhs_.wdata;
    idle_cycles = rhs_.idle_cycles;
    rdata       = rhs_.rdata;
    slverr      = rhs_.slverr;
  endfunction

  // -------------------------------------------------------------------------
  // do_compare
  // -------------------------------------------------------------------------
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    apb_seq_item rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (super.do_compare(rhs, comparer) &&
            addr  === rhs_.addr             &&
            write === rhs_.write            &&
            wdata === rhs_.wdata            &&
            rdata === rhs_.rdata            &&
            slverr=== rhs_.slverr);
  endfunction

  // -------------------------------------------------------------------------
  // convert2string
  // -------------------------------------------------------------------------
  function string convert2string();
    return $sformatf(
      "APB %s addr=0x%04h wdata=0x%08h rdata=0x%08h slverr=%0b idle=%0d",
      write ? "WR" : "RD",
      addr, wdata, rdata, slverr, idle_cycles
    );
  endfunction

endclass : apb_seq_item