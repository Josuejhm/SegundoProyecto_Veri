////////////////////////////////////////////////////////////////////////////////
// Archivo:     apb_irq_clear_seq.sv
// Descripción: Secuencia APB para manejar el registro IRQ (W1C).
//              Primero lee IRQ para capturar los bits activos, luego
//              escribe de vuelta los bits activos para limpiarlos (W1C).
//
//              Opcionalmente permite limpiar solo un subconjunto de bits
//              via clear_mask. Si clear_mask = '1 (default), limpia todos
//              los bits activos que encuentre.
//
//              Expone irq_before y irq_after para que el scoreboard o la
//              virtual sequence puedan verificar el comportamiento W1C.
///////////////////////////////////////////////////////////////////////////////

class apb_irq_clear_seq extends apb_base_seq;
  `uvm_object_utils(apb_irq_clear_seq)

  // Máscara de bits a limpiar — default todos los [4:0]
  bit [31:0]   clear_mask = 32'h0000_001F;
  int unsigned idle       = 0;

  // Capturados al final
  bit [31:0] irq_before;  // valor de IRQ antes de limpiar
  bit [31:0] irq_after;   // valor de IRQ después de limpiar (verificación)
  bit        slverr_read;
  bit        slverr_write;

  function new(string name = "apb_irq_clear_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] rdata;
    bit [31:0] wdata;

    // 1. Leer IRQ para capturar bits activos
    read(aligner_pkg::ADDR_IRQ, rdata, slverr_read, idle);
    irq_before = rdata;

    if (slverr_read)
      `uvm_error("APB_IRQ_CLR_SEQ", "pslverr=1 inesperado en lectura de IRQ")

    // 2. Escribir W1C — solo los bits activos dentro de clear_mask
    wdata = irq_before & clear_mask;

    if (wdata != '0) begin
      write(aligner_pkg::ADDR_IRQ, wdata, slverr_write, idle);
      if (slverr_write)
        `uvm_error("APB_IRQ_CLR_SEQ", "pslverr=1 inesperado en write W1C de IRQ")
    end else begin
      `uvm_info("APB_IRQ_CLR_SEQ",
        "No hay bits IRQ activos dentro de clear_mask — write omitido", UVM_HIGH)
    end

    // 3. Releer IRQ para verificar que se limpiaron
    read(aligner_pkg::ADDR_IRQ, rdata, slverr_read, idle);
    irq_after = rdata;

    `uvm_info("APB_IRQ_CLR_SEQ",
      $sformatf("IRQ before=0x%08h written=0x%08h after=0x%08h",
                irq_before, wdata, irq_after), UVM_MEDIUM)

    // Advertencia si algún bit no se limpió (puede ser re-set por condición activa)
    if ((irq_after & wdata) != '0)
      `uvm_info("APB_IRQ_CLR_SEQ",
        $sformatf("Bits IRQ[0x%08h] aún activos tras W1C — condición puede persistir",
                  irq_after & wdata), UVM_MEDIUM)
  endtask

endclass : apb_irq_clear_seq