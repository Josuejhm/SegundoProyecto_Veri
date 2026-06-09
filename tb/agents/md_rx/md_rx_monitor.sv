///////////////////////////////////////////////////////////////////////////////
// File:        md_rx_monitor.sv
// Description: Monitor para el agente MD RX.
//              Observa pasivamente la interfaz MD RX y publica md_rx_seq_item
//              por md_rx_mon_ap al completarse cada handshake.
//
//              Flujo de detección:
//                1. Esperar posedge donde md_rx_valid=1.
//                2. Capturar data, offset, size (estables durante transfer).
//                3. Esperar posedge donde md_rx_valid=1 AND md_rx_ready=1.
//                4. Capturar md_rx_err → err_captured.
//                5. Publicar item por md_rx_mon_ap.
///////////////////////////////////////////////////////////////////////////////

class md_rx_monitor extends uvm_monitor;
  `uvm_component_utils(md_rx_monitor)

  virtual md_rx_if vif;

  uvm_analysis_port #(md_rx_seq_item) md_rx_mon_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // build_phase
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    md_rx_mon_ap = new("md_rx_mon_ap", this);
    if (!uvm_config_db #(virtual md_rx_if)::get(this, "", "md_rx_vif", vif))
      `uvm_fatal("MD_RX_MON", "No se encontró md_rx_vif en uvm_config_db")
  endfunction

  // -------------------------------------------------------------------------
  // run_phase
  // -------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    @(posedge vif.clk iff vif.reset_n === 1'b1);
    @(vif.monitor_cb);

    forever begin
      collect_transaction();
    end
  endtask

  // -------------------------------------------------------------------------
  // collect_transaction — captura un handshake MD RX completo
  // -------------------------------------------------------------------------
  task collect_transaction();
    md_rx_seq_item item;
    item = md_rx_seq_item::type_id::create("md_rx_mon_item");

    // 1. Esperar valid=1 (inicio del transfer)
    @(vif.monitor_cb iff (vif.monitor_cb.md_rx_valid === 1'b1));

    // 2. Capturar campos (estables desde valid hasta ready)
    item.data   = vif.monitor_cb.md_rx_data;
    item.offset = vif.monitor_cb.md_rx_offset;
    item.size   = vif.monitor_cb.md_rx_size;

    // 3. Esperar fin del handshake: valid=1 AND ready=1
    //    Puede ser el mismo ciclo (md_rx_ready es combinacional)
    while (!(vif.monitor_cb.md_rx_valid === 1'b1 &&
             vif.monitor_cb.md_rx_ready === 1'b1)) begin
      @(vif.monitor_cb);
    end

    // 4. Capturar err en el ciclo del handshake
    item.err_captured = vif.monitor_cb.md_rx_err;

    // 5. Publicar
    `uvm_info("MD_RX_MON", item.convert2string(), UVM_HIGH)
    md_rx_mon_ap.write(item);
  endtask

endclass : md_rx_monitor
