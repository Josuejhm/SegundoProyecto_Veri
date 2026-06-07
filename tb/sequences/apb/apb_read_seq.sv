///////////////////////////////////////////////////////////////////////////////
// File:        apb_read_seq.sv
// Description: APB read sequence — ejecuta un único read APB a una
//              dirección configurable y expone prdata y slverr al llamador.
//              Hereda los helpers de apb_base_seq.
//
//              Uso típico desde una virtual sequence:
//                apb_read_seq seq;
//                seq = apb_read_seq::type_id::create("seq");
//                seq.addr = aligner_pkg::ADDR_STATUS;
//                seq.start(env.vseqr.apb_seqr);
//                // leer resultado:
//                status_val = seq.data;
///////////////////////////////////////////////////////////////////////////////

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