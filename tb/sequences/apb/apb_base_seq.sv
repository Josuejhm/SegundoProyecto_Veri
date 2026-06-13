///////////////////////////////////////////////////////////////////////////////
// File:        apb_base_seq.sv
// Description: Base sequence for all APB sequences.
//              Provides helper tasks for single write and read transactions.
//              All concrete APB sequences inherit from this class.
//
//              Helpers:
//                write(addr, data)  — ejecuta un write APB y retorna slverr
//                read(addr, data)   — ejecuta un read APB y retorna prdata
//
//              Uso:
//                class my_seq extends apb_base_seq;
//                  task body();
//                    write(ADDR_CTRL, 32'h0000_0001);
//                    read(ADDR_STATUS, rdata);
//                  endtask
//                endclass
///////////////////////////////////////////////////////////////////////////////

class apb_base_seq extends uvm_sequence #(apb_seq_item);
  `uvm_object_utils(apb_base_seq)

  function new(string name = "apb_base_seq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  // body — subclases implementan esto
  // -------------------------------------------------------------------------
  virtual task body();
  endtask

  // -------------------------------------------------------------------------
  // write — helper para ejecutar una transacción APB write
  //   addr    : dirección APB (16 bits)
  //   data    : dato a escribir (32 bits)
  //   slverr  : salida — pslverr capturado al final
  //   idle    : ciclos IDLE antes de la transacción (default 0)
  // -------------------------------------------------------------------------
  task write(
    input  bit [15:0] wr_addr,
    input  bit [31:0] data,
    output bit        slverr,
    input  int unsigned idle = 0
  );
    apb_seq_item item;
    item = apb_seq_item::type_id::create("apb_write_item");
    start_item(item);
    item.addr_mapped_c.constraint_mode(0); // deshabilitar mapped para poder escribir a cualquier dirección
    item.addr_unmapped_c.constraint_mode(0); // deshabilitar unmapped para poder escribir a cualquier dirección
    if (!item.randomize() with {
      item.addr        == wr_addr;
      item.write       == 1'b1;
      item.wdata       == data;
      item.idle_cycles == idle;
    })
      `uvm_fatal("APB_BASE_SEQ", "randomize() failed en write()")
    finish_item(item);
    slverr = item.slverr;
  endtask

  // -------------------------------------------------------------------------
  // read — helper para ejecutar una transacción APB read
  //   addr   : dirección APB (16 bits)
  //   data   : salida — prdata capturado al final
  //   slverr : salida — pslverr capturado al final
  //   idle   : ciclos IDLE antes de la transacción (default 0)
  // -------------------------------------------------------------------------
  task read(
    input  bit [15:0] rd_addr,
    output bit [31:0] data,
    output bit        slverr,
    input  int unsigned idle = 0
  );
    apb_seq_item item;
    item = apb_seq_item::type_id::create("apb_read_item");
    start_item(item);
    item.addr_mapped_c.constraint_mode(0); // deshabilitar mapped para poder leer de cualquier dirección
    item.addr_unmapped_c.constraint_mode(0); // deshabilitar unmapped para poder leer de cualquier dirección
    if (!item.randomize() with {
      item.addr        == rd_addr;
      item.write       == 1'b0;
      item.idle_cycles == idle;
    })
      `uvm_fatal("APB_BASE_SEQ", "randomize() failed en read()")
    finish_item(item);
    data   = item.rdata;
    slverr = item.slverr;
  endtask

endclass : apb_base_seq