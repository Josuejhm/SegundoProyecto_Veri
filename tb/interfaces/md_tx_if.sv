////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Archivo:        md_tx_if.sv
// Descripción: Interfaz MD TX para el ambiente UVM del cfs_aligner.
//
//              El DUT es el MAESTRO en esta interfaz:
//                - DUT envía:       md_tx_valid, md_tx_data,
//                                   md_tx_offset, md_tx_size
//                - Driver (TB) responde con: md_tx_ready, md_tx_err
//
//              Los anchos de señal dependen del parámetro ALGN_DATA_WIDTH (establecido via aligner_pkg
//              parameters). La interfaz usa los parámetros del paquete directamente.
//
//              Recordatorio del protocolo MD:
//                - Transferencia empieza cuando valid = 1
//                - Transferencia termina cuando valid = 1 AND ready = 1
//                - Una vez que valid es assertado, data/offset/size debe permanecer estable
//                  hasta que el handshake se complete
//                - err solo es válido al final de la transferencia (ready = 1)
///////////////////////////////////////////////////////////////////////////////////////////////////////////


interface md_tx_if (
  input logic clk,
  input logic reset_n
);

  import aligner_pkg::*;

  // -------------------------------------------------------------------------
  // Declaración de señales MD TX
  // -------------------------------------------------------------------------
  // DUT → TB (Manejado por el DUT)
  logic                              md_tx_valid;
  logic [ALGN_DATA_WIDTH-1:0]        md_tx_data;
  logic [ALGN_OFFSET_WIDTH-1:0]      md_tx_offset;
  logic [ALGN_SIZE_WIDTH-1:0]        md_tx_size;

  // TB → DUT (Manejado por el driver MD TX)
  logic                              md_tx_ready;
  logic                              md_tx_err;

  // -------------------------------------------------------------------------
  // Driver clocking block
  // -------------------------------------------------------------------------
  clocking driver_cb @(posedge clk);
    default output #1;

    output md_tx_ready;
    output md_tx_err;

    input  md_tx_valid;
    input  md_tx_data;
    input  md_tx_offset;
    input  md_tx_size;
  endclocking

  // -------------------------------------------------------------------------
  // Monitor clocking block
  // -------------------------------------------------------------------------
  clocking monitor_cb @(posedge clk);
    default input #1;

    input md_tx_valid;
    input md_tx_data;
    input md_tx_offset;
    input md_tx_size;
    input md_tx_ready;
    input md_tx_err;
  endclocking

  // -------------------------------------------------------------------------
  // Definición de modports
  // -------------------------------------------------------------------------
  modport driver_mp  (clocking driver_cb,  input clk);
  modport monitor_mp (clocking monitor_cb, input clk);

endinterface : md_tx_if