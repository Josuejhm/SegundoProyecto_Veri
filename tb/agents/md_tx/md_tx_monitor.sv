///////////////////////////////////////////////////////////////////////////////
// File:        md_tx_monitor.sv
// Description: Monitor para el agente MD TX.
//              Observa pasivamente la interfaz MD TX y publica md_tx_seq_item
//              por md_tx_mon_ap al completarse cada handshake.
//
//              Solo captura transferencias completadas:
//                md_tx_valid=1 AND md_tx_ready=1
///////////////////////////////////////////////////////////////////////////////

class md_tx_monitor extends uvm_monitor;
  `uvm_component_utils(md_tx_monitor)

  virtual md_tx_if vif;

  uvm_analysis_port #(md_tx_seq_item) md_tx_mon_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // build_phase
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    md_tx_mon_ap = new("md_tx_mon_ap", this);
    if (!uvm_config_db #(virtual md_tx_if)::get(this, "", "md_tx_vif", vif))
      `uvm_fatal("MD_TX_MON", "No se encontró md_tx_vif en uvm_config_db")
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
  // collect_transaction — captura un handshake MD TX completo
  // -------------------------------------------------------------------------
  task collect_transaction();
    md_tx_seq_item item;
    item = md_tx_seq_item::type_id::create("md_tx_mon_item");

    // Esperar handshake completo: valid=1 AND ready=1
    @(vif.monitor_cb iff (vif.monitor_cb.md_tx_valid === 1'b1 &&
                          vif.monitor_cb.md_tx_ready === 1'b1));

    // Capturar campos generados por el DUT
    item.data   = vif.monitor_cb.md_tx_data;
    item.offset = vif.monitor_cb.md_tx_offset;
    item.size   = vif.monitor_cb.md_tx_size;

    `uvm_info("MD_TX_MON", item.convert2string(), UVM_HIGH)
    md_tx_mon_ap.write(item);
  endtask

endclass : md_tx_monitor
