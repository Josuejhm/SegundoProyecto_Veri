/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Archivo:     apb_if.sv
// Descripción: Interfaz APB para el entorno UVM del cfs_aligner.
//              Los anchos coinciden con los valores de los parámetros locales del wrapper cfs_aligner:
//                APB_ADDR_WIDTH = 16
//                APB_DATA_WIDTH = 32
//
//              Contiene:
//                - driver_cb   : clocking block usado por el APB driver
//                - monitor_cb  : clocking block usado por el APB monitor
//              La señal irq no forma parte de esta interfaz; está expuesta como
//              una señal suelta en tb_top (tb_top.irq) y observada directamente
//              por el APB monitor a través de una referencia jerárquica.
/////////////////////////////////////////////////////////////////////////////////////////////////////////

interface apb_if (
  input logic clk,
  input logic reset_n
);

  // -------------------------------------------------------------------------
  // Declaración de señales APB
  // -------------------------------------------------------------------------
  // Maestro → Esclavo (manejado por el APB driver)
  logic [15:0] paddr;
  logic        pwrite;
  logic        psel;
  logic        penable;
  logic [31:0] pwdata;

  // Esclavo → Maestro (manejado por el DUT)
  logic        pready;
  logic [31:0] prdata;
  logic        pslverr;

  // -------------------------------------------------------------------------
  // Driver clocking block
  // -------------------------------------------------------------------------
  clocking driver_cb @(posedge clk);
    default output #1;   // margen de tiempo de setup

    output paddr;
    output pwrite;
    output psel;
    output penable;
    output pwdata;

    input  pready;
    input  prdata;
    input  pslverr;
  endclocking

  // -------------------------------------------------------------------------
  // Monitor clocking block
  // -------------------------------------------------------------------------
  clocking monitor_cb @(posedge clk);
    default input #1;    // margen de tiempo de hold

    input paddr;
    input pwrite;
    input psel;
    input penable;
    input pwdata;
    input pready;
    input prdata;
    input pslverr;
  endclocking

  // -------------------------------------------------------------------------
  // Definición de modports
  // -------------------------------------------------------------------------
  modport driver_mp  (clocking driver_cb,  input clk, input reset_n);
  modport monitor_mp (clocking monitor_cb, input clk, input reset_n);

endinterface : apb_if