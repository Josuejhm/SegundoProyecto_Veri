/////////////////////////////////////////////////////////////////////////////////////
// Archivo:        apb_monitor.sv
// Descripción: Monitor APB para el entorno UVM cfs_aligner.
//              Observa pasivamente la interfaz APB y publica apb_seq_item
//              por el analysis port apb_mon_ap al completarse cada transacción.
//
//              Flujo de detección:
//                1. Espera Setup phase: psel=1 & penable=0.
//                2. Captura addr, write, wdata en Setup.
//                3. Espera Access phase + pready=1: psel=1 & penable=1 & pready=1.
//                4. Captura prdata, pslverr.
//                5. Publica el item por apb_mon_ap.
//
//              El monitor también observa tb_top.irq por referencia jerárquica
//              y lo registra en el item como campo de contexto (no funcional
//              para el protocolo APB, pero útil para el scoreboard de IRQs).
////////////////////////////////////////////////////////////////////////////////////

class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)

  // Puntero de la interfaz virtual
  virtual apb_if vif;

  // Analysis port — publica apb_seq_item al scoreboard y coverage
  uvm_analysis_port #(apb_seq_item) apb_mon_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // build_phase
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_mon_ap = new("apb_mon_ap", this);
    if (!uvm_config_db #(virtual apb_if)::get(this, "", "apb_vif", vif))
      `uvm_fatal("APB_MON", "No se encontró apb_vif en uvm_config_db")
  endfunction

  // -------------------------------------------------------------------------
  // run_phase — loop principal de observación
  // -------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    // Esperar a que salga el reset antes de monitorear
    @(posedge vif.clk iff vif.reset_n === 1'b1);
    @(vif.monitor_cb); // un ciclo extra de estabilización

    forever begin
      collect_transaction();
    end
  endtask

  // -------------------------------------------------------------------------
  // collect_transaction — captura una transacción APB completa
  // -------------------------------------------------------------------------
  task collect_transaction();
    apb_seq_item item;
    item = apb_seq_item::type_id::create("apb_mon_item");

    // 1. Esperar Setup phase: psel=1, penable=0
    @(vif.monitor_cb iff (vif.monitor_cb.psel === 1'b1 &&
                          vif.monitor_cb.penable === 1'b0));

    // 2. Capturar campos de Setup
    item.addr  = vif.monitor_cb.paddr;
    item.write = vif.monitor_cb.pwrite;
    item.wdata = vif.monitor_cb.pwdata;

    // 3. Esperar fin de Access phase: psel=1, penable=1, pready=1
    @(vif.monitor_cb iff (vif.monitor_cb.psel    === 1'b1 &&
                          vif.monitor_cb.penable  === 1'b1 &&
                          vif.monitor_cb.pready   === 1'b1));

    // 4. Capturar respuesta
    item.rdata  = vif.monitor_cb.prdata;
    item.slverr = vif.monitor_cb.pslverr;

    // 5. Log y publicación
    `uvm_info("APB_MON", item.convert2string(), UVM_HIGH)
    apb_mon_ap.write(item);
  endtask

endclass : apb_monitor