//////////////////////////////////////////////////////////////////////////////////////////////////
// Archivo:     apb_config_ctrl_seq.sv
// Descripción: Secuencia APB que escribe el registro CTRL con una combinación
//              legal de SIZE y OFFSET, y opcionalmente activa CLR.
//
//              Por defecto genera SIZE y OFFSET legales aleatoriamente.
//              La virtual sequence puede fijar size/offset antes de start().
//
//              Legalidad: ((ALGN_DATA_WIDTH/8) + offset) % size == 0
//                         AND size != 0
///////////////////////////////////////////////////////////////////////////////

class apb_config_ctrl_seq extends apb_base_seq;
  `uvm_object_utils(apb_config_ctrl_seq)

  // Configurables — si randomize_fields=1 se ignoran y se generan legales
  bit                          randomize_fields = 1'b1;
  bit [2:0]                    size;
  bit [ALGN_OFFSET_WIDTH-1:0]  offset;
  bit                          clr              = 1'b0;
  int unsigned                 idle             = 0;

  // Capturado al final
  bit slverr;

  function new(string name = "apb_config_ctrl_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] wdata;
    bit [2:0]  s;
    bit [1:0]  o;

    if (randomize_fields) begin
      // Generar combinación legal aleatoria
      if (!std::randomize(s, o) with {
        s != 3'b000;
        ((aligner_pkg::ALGN_DATA_WIDTH / 8) + o) % s == 0;
        o < aligner_pkg::ALGN_DATA_WIDTH / 8;
      })
        `uvm_fatal("APB_CFG_CTRL_SEQ", "No se pudo randomizar SIZE/OFFSET legal")
      size   = s;
      offset = o[ALGN_OFFSET_WIDTH-1:0];
    end

    // Construir CTRL word: [2:0]=SIZE, [9:8]=OFFSET, [16]=CLR
    wdata = '0;
    wdata[2:0]  = size;
    wdata[9:8]  = offset;
    wdata[16]   = clr;

    write(aligner_pkg::ADDR_CTRL, wdata, slverr, idle);

    if (slverr)
      `uvm_error("APB_CFG_CTRL_SEQ",
        $sformatf("pslverr=1 inesperado en CTRL write legal: SIZE=%0d OFFSET=%0d CLR=%0b",
                  size, offset, clr))
    else
      `uvm_info("APB_CFG_CTRL_SEQ",
        $sformatf("CTRL configurado: SIZE=%0d OFFSET=%0d CLR=%0b",
                  size, offset, clr), UVM_MEDIUM)
  endtask

endclass : apb_config_ctrl_seq