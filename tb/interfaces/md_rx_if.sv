///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Archivo:     md_rx_if.sv
// Descripción: Interfaz MD RX para el ambiente UVM del cfs_aligner.
//
//              El DUT es el ESCLAVO en esta interfaz:
//                - Driver (TB) envía:   md_rx_valid, md_rx_data,
//                                       md_rx_offset, md_rx_size
//                - DUT responds with:   md_rx_ready, md_rx_err
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
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

interface md_rx_if (
  input logic clk,
  input logic reset_n
);

  import aligner_pkg::*;

  // -------------------------------------------------------------------------
  // Declaración de señales MD RX
  // -------------------------------------------------------------------------
  // TB → DUT (Manejado por el driver MD RX)
  logic                              md_rx_valid;
  logic [ALGN_DATA_WIDTH-1:0]        md_rx_data;
  logic [ALGN_OFFSET_WIDTH-1:0]      md_rx_offset;
  logic [ALGN_SIZE_WIDTH-1:0]        md_rx_size;

  // DUT → TB (Manejado por el DUT)
  logic                              md_rx_ready;
  logic                              md_rx_err;

  // -------------------------------------------------------------------------
  // Driver clocking block
  // -------------------------------------------------------------------------
  clocking driver_cb @(posedge clk);
    default output #1;

    output md_rx_valid;
    output md_rx_data;
    output md_rx_offset;
    output md_rx_size;

    input  md_rx_ready;
    input  md_rx_err;
  endclocking

  // -------------------------------------------------------------------------
  // Monitor clocking block
  // -------------------------------------------------------------------------
  clocking monitor_cb @(posedge clk);
    default input #1;

    input md_rx_valid;
    input md_rx_data;
    input md_rx_offset;
    input md_rx_size;
    input md_rx_ready;
    input md_rx_err;
  endclocking

  // -------------------------------------------------------------------------
  // Definición de modports
  // -------------------------------------------------------------------------
  modport driver_mp  (clocking driver_cb,  input clk);
  modport monitor_mp (clocking monitor_cb, input clk);

endinterface : md_rx_if