////////////////////////////////////////////////////////////////////////////////////////////////
// Archivo:     apb_read_seq.sv
// Descripción: Secuencia APB para leer un único registro — ejecuta un único read APB a una
//              dirección configurable y expone prdata y slverr al llamador.
//              Hereda los helpers de apb_base_seq.
////////////////////////////////////////////////////////////////////////////////////////////////

class apb_read_seq extends apb_base_seq;
  `uvm_object_utils(apb_read_seq)

  // Configurables por la virtual sequence antes de llamar start()
  bit [15:0]   addr = aligner_pkg::ADDR_STATUS;
  int unsigned idle = 0;

  // Capturados al final de la transacción
  bit [31:0] data;
  bit        slverr;

  function new(string name = "apb_read_seq");
    super.new(name);
  endfunction

  task body();
    read(addr, data, slverr, idle);
    if (slverr)
      `uvm_info("APB_READ_SEQ",
        $sformatf("pslverr=1 en read addr=0x%04h", addr),
        UVM_MEDIUM)
  endtask

endclass : apb_read_seq