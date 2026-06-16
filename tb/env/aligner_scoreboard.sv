///////////////////////////////////////////////////////////////////////////////
// File:        aligner_scoreboard.sv
// Description: Scoreboard para el ambiente cfs_aligner.
//
//              Recibe transacciones de los tres monitores y realiza:
//                1. Checkers de protocolo (APB, MD RX, MD TX).
//                2. Modelo de referencia: predice los transfers TX esperados
//                   a partir del stream RX y la configuración CTRL.
//                3. Comparador: confronta predicciones con observaciones TX.
//
//              BUG DOCUMENTADO DEL DUT:
//                El pulso irq NO incluye MAX_DROP aunque IRQEN.MAX_DROP=1.
//                El scoreboard modela el comportamiento REAL del DUT,
//                no lo que dice el datasheet.
///////////////////////////////////////////////////////////////////////////////

// Macro para los tres analysis imp con tipos distintos
`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_md_rx)
`uvm_analysis_imp_decl(_md_tx)

class aligner_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(aligner_scoreboard)

  // -------------------------------------------------------------------------
  // Analysis imports — el env conecta los tres monitors aquí
  // -------------------------------------------------------------------------
  uvm_analysis_imp_apb   #(apb_seq_item,   aligner_scoreboard) apb_export;
  uvm_analysis_imp_md_rx #(md_rx_seq_item, aligner_scoreboard) md_rx_export;
  uvm_analysis_imp_md_tx #(md_tx_seq_item, aligner_scoreboard) md_tx_export;

  // -------------------------------------------------------------------------
  // Estado del modelo de referencia
  // -------------------------------------------------------------------------
  // Configuración CTRL actual (actualizada con cada write exitoso a CTRL)
  bit [2:0] ref_size   = 3'b001; // reset value
  bit [1:0] ref_offset = 2'b00;  // reset value

  // Cola de bytes pendientes de alinear
  // Cada byte se almacena como int unsigned para simplificar
  int unsigned byte_queue[$];

  // Cola de transfers TX predichos
  md_tx_seq_item expected_tx[$];

  // Estado de IRQ y IRQEN (para checker de IRQ)
  bit [31:0] ref_irqen = aligner_pkg::IRQEN_RESET_VAL;
  bit [31:0] ref_irq   = aligner_pkg::IRQ_RESET_VAL;

  // Contadores
  int unsigned tx_received  = 0;
  int unsigned tx_predicted = 0;
  int unsigned rx_legal     = 0;
  int unsigned rx_illegal   = 0;
  int unsigned errors       = 0;

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // build_phase — crear los tres analysis imports
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_export   = new("apb_export",   this);
    md_rx_export = new("md_rx_export", this);
    md_tx_export = new("md_tx_export", this);
  endfunction

  // =========================================================================
  // write_apb — llamado por el monitor APB
  // =========================================================================
  function void write_apb(apb_seq_item item);

    // --- Checker APB: pslverr solo en escenarios correctos ---
    if (item.slverr) begin
      bit expected_err = 0;

      // Errores esperados:
      // 1. Dirección no mapeada
      if (!(item.addr inside {aligner_pkg::ADDR_CTRL,
                              aligner_pkg::ADDR_STATUS,
                              aligner_pkg::ADDR_IRQEN,
                              aligner_pkg::ADDR_IRQ}))
        expected_err = 1;

      // 2. Write a STATUS (read-only)
      if (item.write && item.addr == aligner_pkg::ADDR_STATUS)
        expected_err = 1;

      // 3. Write ilegal a CTRL
      if (item.write && item.addr == aligner_pkg::ADDR_CTRL &&
          is_ctrl_illegal(item.wdata))
        expected_err = 1;

      if (!expected_err) begin
        `uvm_error("SCOREBOARD",
          $sformatf("pslverr=1 inesperado: %s", item.convert2string()))
        errors++;
      end
    end

    // --- Actualizar modelo de referencia ---
    if (item.write && !item.slverr) begin

      // Write exitoso a CTRL → actualizar ref_size y ref_offset
      if (item.addr == aligner_pkg::ADDR_CTRL) begin
        ref_size   = item.wdata[aligner_pkg::CTRL_SIZE_MSB :
                                aligner_pkg::CTRL_SIZE_LSB];
        ref_offset = item.wdata[aligner_pkg::CTRL_OFFSET_MSB :
                                aligner_pkg::CTRL_OFFSET_LSB];
        `uvm_info("SCOREBOARD",
          $sformatf("CTRL actualizado: SIZE=%0d OFFSET=%0d",
                    ref_size, ref_offset), UVM_HIGH)

        // CLR=1 → limpiar byte_queue (el drop counter se limpia en el DUT)
        if (item.wdata[aligner_pkg::CTRL_CLR_BIT]) begin
          `uvm_info("SCOREBOARD", "CLR=1 recibido — CNT_DROP reseteado en DUT",
                    UVM_MEDIUM)
        end
      end

      // Write a IRQEN → actualizar referencia
      if (item.addr == aligner_pkg::ADDR_IRQEN) begin
        ref_irqen = item.wdata & 32'h0000_001F;
      end

      // Write W1C a IRQ → limpiar bits
      if (item.addr == aligner_pkg::ADDR_IRQ) begin
        ref_irq = ref_irq & ~(item.wdata & 32'h0000_001F);
      end
    end

    // --- Checker de lectura CTRL: prdata debe reflejar ref_size/ref_offset ---
    if (!item.write && !item.slverr && item.addr == aligner_pkg::ADDR_CTRL) begin
      bit [2:0] rd_size   = item.rdata[aligner_pkg::CTRL_SIZE_MSB :
                                        aligner_pkg::CTRL_SIZE_LSB];
      bit [1:0] rd_offset = item.rdata[aligner_pkg::CTRL_OFFSET_MSB :
                                        aligner_pkg::CTRL_OFFSET_LSB];
      bit       rd_clr    = item.rdata[aligner_pkg::CTRL_CLR_BIT];

      if (rd_size !== ref_size) begin
        `uvm_error("SCOREBOARD",
          $sformatf("CTRL.SIZE leído=%0d != esperado=%0d",
                    rd_size, ref_size))
        errors++;
      end
      if (rd_offset !== ref_offset) begin
        `uvm_error("SCOREBOARD",
          $sformatf("CTRL.OFFSET leído=%0d != esperado=%0d",
                    rd_offset, ref_offset))
        errors++;
      end
      // CLR es WO — lectura siempre debe retornar 0
      if (rd_clr !== 1'b0) begin
        `uvm_error("SCOREBOARD",
          "CTRL.CLR leído != 0 — campo WO debe retornar siempre 0")
        errors++;
      end
    end

  endfunction : write_apb

  // =========================================================================
  // write_md_rx — llamado por el monitor MD RX
  // =========================================================================
  function void write_md_rx(md_rx_seq_item item);
    bit expected_err;
    int unsigned byte_val;
    int unsigned i;

    // --- Checker MD RX: err_captured debe coincidir con legalidad real ---
    expected_err = is_rx_illegal(item.offset, item.size);

    if (item.err_captured !== expected_err) begin
      `uvm_error("SCOREBOARD",
        $sformatf("md_rx_err=%0b pero se esperaba %0b para offset=%0d size=%0d",
                  item.err_captured, expected_err, item.offset, item.size))
      errors++;
    end

    // --- Modelo de referencia ---
    if (item.err_captured) begin
      // Transfer ilegal — descartar, solo contar
      rx_illegal++;
      `uvm_info("SCOREBOARD",
        $sformatf("RX ilegal descartado: offset=%0d size=%0d",
                  item.offset, item.size), UVM_HIGH)
    end else begin
      rx_legal++;
      // Transfer legal — extraer bytes válidos y agregarlos a byte_queue
      // Los bytes válidos están en data[(offset*8) +: (size*8)]
      for (i = 0; i < item.size; i++) begin
        byte_val = (item.data >> ((item.offset + i) * 8)) & 8'hFF;
        byte_queue.push_back(byte_val);
      end

      // Intentar generar transfers TX desde byte_queue
      generate_tx_predictions();
    end

  endfunction : write_md_rx

  // =========================================================================
  // write_md_tx — llamado por el monitor MD TX
  // =========================================================================
  function void write_md_tx(md_tx_seq_item item);
    md_tx_seq_item exp;

    tx_received++;

    // --- Checker MD TX: offset y size deben coincidir con CTRL ---
    if (item.offset !== ref_offset) begin
      `uvm_error("SCOREBOARD",
        $sformatf("TX offset=%0d != CTRL.OFFSET=%0d",
                  item.offset, ref_offset))
      errors++;
    end
    if (item.size !== ref_size) begin
      `uvm_error("SCOREBOARD",
        $sformatf("TX size=%0d != CTRL.SIZE=%0d",
                  item.size, ref_size))
      errors++;
    end

    // --- Checker: combinación TX siempre debe ser legal ---
    if (is_rx_illegal(item.offset, item.size)) begin
      `uvm_error("SCOREBOARD",
        $sformatf("DUT generó TX con combo ilegal: offset=%0d size=%0d",
                  item.offset, item.size))
      errors++;
    end

    // --- Comparación con modelo de referencia ---
    if (expected_tx.size() == 0) begin
      `uvm_error("SCOREBOARD",
        $sformatf("TX inesperado recibido: %s", item.convert2string()))
      errors++;
      return;
    end

    exp = expected_tx.pop_front();

    // Comparar solo los bytes válidos en la posición ref_offset
    begin
      bit [aligner_pkg::ALGN_DATA_WIDTH-1:0] mask;
      bit [aligner_pkg::ALGN_DATA_WIDTH-1:0] exp_masked;
      bit [aligner_pkg::ALGN_DATA_WIDTH-1:0] act_masked;

      // Máscara: ref_size bytes a partir de ref_offset
      mask = ((1 << (ref_size * 8)) - 1) << (ref_offset * 8);
      exp_masked = exp.data & mask;
      act_masked = item.data & mask;

      if (exp_masked !== act_masked) begin
        `uvm_error("SCOREBOARD",
          $sformatf("Datos TX no coinciden: expected=0x%0h actual=0x%0h (mask=0x%0h)",
                    exp_masked, act_masked, mask))
        errors++;
      end else begin
        `uvm_info("SCOREBOARD",
          $sformatf("TX verificado OK: data=0x%0h offset=%0d size=%0d",
                    item.data, item.offset, item.size), UVM_HIGH)
      end
    end

  endfunction : write_md_tx

  // =========================================================================
  // generate_tx_predictions — genera predicciones TX desde byte_queue
  // =========================================================================
  function void generate_tx_predictions();
    while (byte_queue.size() >= ref_size) begin
      md_tx_seq_item pred;
      int unsigned i;
      bit [aligner_pkg::ALGN_DATA_WIDTH-1:0] tx_data;

      pred = md_tx_seq_item::type_id::create("pred");
      pred.size   = ref_size;
      pred.offset = ref_offset;
      tx_data     = '0;

      // Colocar ref_size bytes en la posición ref_offset del bus TX
      for (i = 0; i < ref_size; i++) begin
        tx_data |= (byte_queue[i] << ((ref_offset + i) * 8));
      end

      // Consumir los bytes usados
      repeat (ref_size) void'(byte_queue.pop_front());

      pred.data = tx_data;
      expected_tx.push_back(pred);
      tx_predicted++;

      `uvm_info("SCOREBOARD",
        $sformatf("TX predicho: data=0x%0h offset=%0d size=%0d",
                  tx_data, ref_offset, ref_size), UVM_HIGH)
    end
  endfunction

  // =========================================================================
  // is_ctrl_illegal — retorna 1 si la escritura a CTRL es ilegal
  // =========================================================================
  function bit is_ctrl_illegal(bit [31:0] wdata);
    bit [2:0] s;
    bit [1:0] o;
    s = wdata[aligner_pkg::CTRL_SIZE_MSB : aligner_pkg::CTRL_SIZE_LSB];
    o = wdata[aligner_pkg::CTRL_OFFSET_MSB : aligner_pkg::CTRL_OFFSET_LSB];
    if (s == 0) return 1'b1;
    if (((aligner_pkg::ALGN_DATA_WIDTH / 8) + o) % s != 0) return 1'b1;
    return 1'b0;
  endfunction

  // =========================================================================
  // is_rx_illegal — retorna 1 si la combinación (offset, size) es ilegal
  // =========================================================================
  function bit is_rx_illegal(
    bit [aligner_pkg::ALGN_OFFSET_WIDTH-1:0] offset,
    bit [aligner_pkg::ALGN_SIZE_WIDTH-1:0]   size
  );
    if (size == 0) return 1'b1;
    if (((aligner_pkg::ALGN_DATA_WIDTH / 8) + offset) % size != 0) return 1'b1;
    return 1'b0;
  endfunction

  // =========================================================================
  // check_phase — verificación final
  // =========================================================================
  function void check_phase(uvm_phase phase);
    // Leer drain_tx para distinguir entre error real y corner intencional
    begin
      int unsigned tmp;
      bit drain_tx = 1'b1;
      if ($value$plusargs("drain_tx=%0d", tmp)) drain_tx = tmp[0];

      if (expected_tx.size() > 0) begin
        if (drain_tx) begin
          // drain_tx=1: transfers pendientes son un error real del DUT
          `uvm_error("SCOREBOARD",
            $sformatf("%0d transfers TX predichos pero no recibidos al final",
                      expected_tx.size()))
          errors += expected_tx.size();
        end else begin
          // drain_tx=0: corner intencional donde la FIFO queda llena al terminar
          `uvm_info("SCOREBOARD",
            $sformatf("%0d transfers TX pendientes en FIFO al terminar (drain_tx=0 — esperado)",
                      expected_tx.size()), UVM_MEDIUM)
        end
      end
    end

    `uvm_info("SCOREBOARD",
      $sformatf(
        "=== RESUMEN SCOREBOARD ===\n" +
        "  TX recibidos  : %0d\n"      +
        "  TX predichos  : %0d\n"      +
        "  RX legales    : %0d\n"      +
        "  RX ilegales   : %0d\n"      +
        "  Errores       : %0d",
        tx_received, tx_predicted, rx_legal, rx_illegal, errors),
      UVM_NONE)
  endfunction

  // =========================================================================
  // wait_tx_empty — bloquea hasta que expected_tx esté vacía o timeout
  // Llamada desde el test antes de drop_objection para garantizar que el
  // monitor TX procesó todas las transacciones antes del check_phase.
  // =========================================================================
  task wait_tx_empty(int unsigned timeout_cycles = 10000);
    int unsigned count = 0;
    while (expected_tx.size() > 0 && count < timeout_cycles) begin
      #10ns;
      count++;
    end
    if (expected_tx.size() > 0)
      `uvm_warning("SCOREBOARD",
        $sformatf("wait_tx_empty: timeout tras %0d ciclos, quedan %0d pendientes",
                  timeout_cycles, expected_tx.size()))
  endtask

endclass : aligner_scoreboard
