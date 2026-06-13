///////////////////////////////////////////////////////////////////////////////
// File:        apb_driver.sv
// Description: APB driver for the cfs_aligner UVM environment.
//              Implements APB3 master protocol.
//
//              Flujo por transacción:
//                1. IDLE   — psel=0, penable=0 durante idle_cycles ciclos.
//                2. SETUP  — psel=1, penable=0, coloca addr/write/wdata (1 ciclo).
//                3. ACCESS — penable=1, espera pready=1 del DUT.
//                            Timeout: 5 ciclos (spec APB3), excepto write ilegal
//                            a CTRL que tolera 2 ciclos (ver sección 2.5 del doc).
//                4. Captura prdata/pslverr y llama item_done().
//                5. Regresa a IDLE.
//
//              Nota: el driver detecta write ilegal a CTRL para ajustar el
//              timeout, pero NO genera pslverr — eso lo decide el DUT.
///////////////////////////////////////////////////////////////////////////////

class apb_driver extends uvm_driver #(apb_seq_item);
  `uvm_component_utils(apb_driver)

  // Virtual interface handle
  virtual apb_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // build_phase — obtener la virtual interface del config_db
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual apb_if)::get(this, "", "apb_vif", vif))
      `uvm_fatal("APB_DRV", "No se encontró apb_vif en uvm_config_db")
  endfunction

  // -------------------------------------------------------------------------
  // run_phase — loop principal
  // -------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    // Inicializar señales en IDLE antes de que salga el reset
    drive_idle();
    @(posedge vif.clk iff vif.reset_n === 1'b1);
    @(vif.driver_cb);       // Esperar un ciclo extra para que el DUT se estabilice 

    forever begin
      apb_seq_item item;
      seq_item_port.get_next_item(item);
      drive_transaction(item);
      seq_item_port.item_done();
    end
  endtask

  // -------------------------------------------------------------------------
  // drive_idle — coloca bus en estado IDLE
  // -------------------------------------------------------------------------
  task drive_idle();
    vif.driver_cb.psel    <= 1'b0;
    vif.driver_cb.penable <= 1'b0;
    vif.driver_cb.paddr   <= '0;
    vif.driver_cb.pwrite  <= 1'b0;
    vif.driver_cb.pwdata  <= '0;
  endtask

  // -------------------------------------------------------------------------
  // drive_transaction — maneja una transacción APB completa
  // -------------------------------------------------------------------------
  task drive_transaction(apb_seq_item item);
    int unsigned max_wait;

    // 1. IDLE — esperar idle_cycles ciclos
    drive_idle();
    repeat (item.idle_cycles) @(vif.driver_cb);

    `uvm_info("APB_DRV_DBG",
      $sformatf(("NUEVA TXN: addr=0x%04h write=%0b wdata=0x%08h",
                item.addr, item.write, item.wdata), UVM_NONE)

    // 2. SETUP — 1 ciclo con psel=1, penable=0
    vif.driver_cb.paddr   <= item.addr;
    vif.driver_cb.pwrite  <= item.write;
    vif.driver_cb.pwdata  <= item.wdata;
    vif.driver_cb.psel    <= 1'b1;
    vif.driver_cb.penable <= 1'b0;
    @(vif.driver_cb);

    // 3. ACCESS — psel=1, penable=1, esperar pready
    vif.driver_cb.penable <= 1'b1;

    // Determinar timeout: write ilegal a CTRL → 2 ciclos, resto → 5 ciclos
    if (item.write && (item.addr[15:2] == aligner_pkg::ADDR_CTRL[15:2]) &&
        is_ctrl_illegal(item.wdata))
      max_wait = aligner_pkg::APB_MAX_WAIT_CYCLES_ILLEGAL;
    else
      max_wait = aligner_pkg::APB_MAX_WAIT_CYCLES;

    begin : wait_pready
      int unsigned wait_count = 0;
      @(vif.driver_cb);
      `uvm_info("APB_DRV_DBG",
        $sformatf("ACCESS ciclo 0: pready=%0b pslverr=%0b psel=%0b penable=%0b addr=0x%04h pwdata=0x%08h",
                  vif.driver_cb.pready, vif.driver_cb.pslverr,
                  vif.psel, vif.penable,
                  vif.paddr, vif.pwdata), UVM_NONE)
      while (!vif.driver_cb.pready) begin
        wait_count++;
        `uvm_info("APB_DRV_DBG",
          $sformatf("ACCESS ciclo %0d: pready=%0b pslverr=%0b",
                    wait_count, vif.driver_cb.pready, vif.driver_cb.pslverr), UVM_NONE)
        if (wait_count > max_wait)
          `uvm_error("APB_DRV",
            $sformatf("pready timeout tras %0d ciclos: addr=0x%04h write=%0b",
                      wait_count, item.addr, item.write))
        @(vif.driver_cb);
      end
      `uvm_info("APB_DRV_DBG",
        $sformatf("ACCESS done: pready=%0b pslverr=%0b",
                  vif.driver_cb.pready, vif.driver_cb.pslverr), UVM_NONE)
    end

    // 4. Capturar respuesta
    item.rdata  = vif.driver_cb.prdata;
    item.slverr = vif.driver_cb.pslverr;

    // 5. Regresa a IDLE
    @(vif.driver_cb);
    drive_idle();
  endtask

  // -------------------------------------------------------------------------
  // is_ctrl_illegal — devuelve 1 si la combinación SIZE/OFFSET en wdata es
  // ilegal según el protocolo del DUT (size=0 o condición de alineación falla)
  // -------------------------------------------------------------------------
  function bit is_ctrl_illegal(bit [31:0] wdata);
    bit [2:0] size;
    bit [1:0] offset;
    size   = wdata[2:0];
    offset = wdata[9:8];
    if (size == 3'b000) return 1'b1;
    if (((aligner_pkg::ALGN_DATA_WIDTH / 8) + offset) % size != 0) return 1'b1;
    return 1'b0;
  endfunction

endclass : apb_driver