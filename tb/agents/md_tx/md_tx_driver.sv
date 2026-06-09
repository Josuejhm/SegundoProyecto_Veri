///////////////////////////////////////////////////////////////////////////////
// File:        md_tx_driver.sv
// Description: Driver para el agente MD TX.
//              Actúa como receptor (esclavo) del stream alineado que
//              el DUT genera.
//
//              ATENCIÓN — md_tx_valid es COMBINACIONAL en el DUT:
//                El DUT puede asertar md_tx_valid en cualquier momento
//                una vez que tiene datos en la TX FIFO. El driver debe
//                mantener ready=1 hasta completar el handshake y no
//                asumir que valid llega un ciclo después.
//
//              Flujo por transacción:
//                1. Mantener md_tx_ready=0 durante ready_delay ciclos.
//                   Durante este tiempo el DUT puede tener valid=1
//                   (backpressure real).
//                2. Asertar md_tx_ready=1.
//                3. Esperar posedge donde md_tx_valid=1 AND md_tx_ready=1.
//                4. Si item.err=1, asertar md_tx_err=1 en ese ciclo.
//                5. Ciclo siguiente: bajar ready=0 y err=0.
//                6. item_done().
///////////////////////////////////////////////////////////////////////////////

class md_tx_driver extends uvm_driver #(md_tx_seq_item);
  `uvm_component_utils(md_tx_driver)

  virtual md_tx_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // build_phase
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual md_tx_if)::get(this, "", "md_tx_vif", vif))
      `uvm_fatal("MD_TX_DRV", "No se encontró md_tx_vif en uvm_config_db")
  endfunction

  // -------------------------------------------------------------------------
  // run_phase
  // -------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    // Inicializar señales
    vif.driver_cb.md_tx_ready <= 1'b0;
    vif.driver_cb.md_tx_err   <= 1'b0;
    @(posedge vif.clk iff vif.reset_n === 1'b1);
    @(vif.driver_cb);

    forever begin
      md_tx_seq_item item;
      seq_item_port.get_next_item(item);
      drive_transaction(item);
      seq_item_port.item_done();
    end
  endtask

  // -------------------------------------------------------------------------
  // drive_transaction — maneja una respuesta TX completa
  // -------------------------------------------------------------------------
  task drive_transaction(md_tx_seq_item item);

    // 1. Backpressure: mantener ready=0 durante ready_delay ciclos
    vif.driver_cb.md_tx_ready <= 1'b0;
    vif.driver_cb.md_tx_err   <= 1'b0;
    repeat (item.ready_delay) @(vif.driver_cb);

    // 2. Asertar ready=1
    vif.driver_cb.md_tx_ready <= 1'b1;

    // 3. Esperar el handshake: valid=1 AND ready=1
    //    md_tx_valid es combinacional — puede ya estar en 1
    @(vif.driver_cb);
    while (!(vif.driver_cb.md_tx_valid === 1'b1)) begin
      @(vif.driver_cb);
    end
    // En este ciclo ocurre el handshake (valid=1 y ready=1)

    // 4. Asertar err si el item lo requiere
    if (item.err) begin
      vif.driver_cb.md_tx_err <= 1'b1;
    end

    // 5. Ciclo siguiente: bajar ready y err
    @(vif.driver_cb);
    vif.driver_cb.md_tx_ready <= 1'b0;
    vif.driver_cb.md_tx_err   <= 1'b0;

    `uvm_info("MD_TX_DRV", item.convert2string(), UVM_HIGH)
  endtask

endclass : md_tx_driver
