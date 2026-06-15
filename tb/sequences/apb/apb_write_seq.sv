//////////////////////////////////////////////////////////////////////////////////////////////////
// Archivo:     apb_write_seq.sv
// Descripción: Secuencia APB para escribir un único registro — ejecuta un único write APB a una
//              dirección y dato configurables.
//              Hereda los helpers de apb_base_seq.
//////////////////////////////////////////////////////////////////////////////////////////////////

class apb_write_seq extends apb_base_seq;
  `uvm_object_utils(apb_write_seq)

  // Configurables por la virtual sequence antes de llamar start()
  bit [15:0]   addr  = aligner_pkg::ADDR_CTRL;
  bit [31:0]   data  = '0;
  int unsigned idle  = 0;

  // Capturado al final de la transacción
  bit slverr;

  function new(string name = "apb_write_seq");
    super.new(name);
  endfunction

  task body();
    write(addr, data, slverr, idle);
    if (slverr)
      `uvm_info("APB_WRITE_SEQ",
        $sformatf("pslverr=1 en write addr=0x%04h data=0x%08h", addr, data),
        UVM_MEDIUM)
  endtask

endclass : apb_write_seq