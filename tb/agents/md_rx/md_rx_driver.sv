///////////////////////////////////////////////////////////////////////////////
// File:        md_rx_driver.sv
// Description: Driver para el agente MD RX.
//              Implementa el protocolo MD como maestro (productor de datos).
//
//              ATENCIÓN — md_rx_ready es COMBINACIONAL en el DUT:
//                El DUT puede asertar md_rx_ready en el mismo ciclo
//                en que el driver aserta md_rx_valid. Por esto el driver
//                muestrea ready DESPUÉS del flanco de reloj usando el
//                clocking block, no antes.
//
//              Flujo por transacción:
//                1. IDLE: md_rx_valid=0 durante idle_cycles ciclos.
//                2. Asertar md_rx_valid=1, colocar data/offset/size.
//                3. Esperar posedge donde md_rx_ready=1 (fin del handshake).
//                4. Capturar md_rx_err en ese ciclo → item.err_captured.
//                5. Bajar md_rx_valid=0.
//                6. item_done().
///////////////////////////////////////////////////////////////////////////////

class md_rx_driver extends uvm_driver #(md_rx_seq_item);
  `uvm_component_utils(md_rx_driver)

  virtual md_rx_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // build_phase
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual md_rx_if)::get(this, "", "md_rx_vif", vif))
      `uvm_fatal("MD_RX_DRV", "No se encontró md_rx_vif en uvm_config_db")
  endfunction

  // -------------------------------------------------------------------------
  // run_phase
  // -------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    // Inicializar señales en IDLE antes de que salga el reset
    drive_idle();
    @(posedge vif.clk iff vif.reset_n === 1'b1);
    @(vif.driver_cb); // ciclo de estabilización

    forever begin
      md_rx_seq_item item;
      seq_item_port.get_next_item(item);
      drive_transaction(item);
      seq_item_port.item_done();
    end
  endtask

  // -------------------------------------------------------------------------
  // drive_idle — bus en estado inactivo
  // -------------------------------------------------------------------------
  task drive_idle();
    vif.driver_cb.md_rx_valid  <= 1'b0;
    vif.driver_cb.md_rx_data   <= '0;
    vif.driver_cb.md_rx_offset <= '0;
    vif.driver_cb.md_rx_size   <= '0;
  endtask

  // -------------------------------------------------------------------------
  // drive_transaction — maneja un transfer MD RX completo
  // -------------------------------------------------------------------------
  task drive_transaction(md_rx_seq_item item);

    // 1. IDLE — esperar idle_cycles ciclos
    drive_idle();
    repeat (item.idle_cycles) @(vif.driver_cb);

    // 2. Asertar valid y colocar el dato
    vif.driver_cb.md_rx_valid  <= 1'b1;
    vif.driver_cb.md_rx_data   <= item.data;
    vif.driver_cb.md_rx_offset <= item.offset;
    vif.driver_cb.md_rx_size   <= item.size;

    // 3. Esperar handshake: muestrar ready DESPUÉS del flanco
    //    md_rx_ready es combinacional — puede llegar en el primer ciclo
    @(vif.driver_cb);
    while (!vif.driver_cb.md_rx_ready) @(vif.driver_cb);

    // 4. Capturar err en el ciclo del handshake
    item.err_captured = vif.driver_cb.md_rx_err;

    // 5. Bajar valid
    vif.driver_cb.md_rx_valid  <= 1'b0;
    vif.driver_cb.md_rx_data   <= '0;
    vif.driver_cb.md_rx_offset <= '0;
    vif.driver_cb.md_rx_size   <= '0;

    `uvm_info("MD_RX_DRV", item.convert2string(), UVM_HIGH)
  endtask

endclass : md_rx_driver
