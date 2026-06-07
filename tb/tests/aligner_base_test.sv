///////////////////////////////////////////////////////////////////////////////
// File:        aligner_base_test.sv
// Description: Base test for the cfs_aligner UVM environment.
//              Todos los tests concretos heredan de este.
//
//              Responsabilidades:
//                - Instanciar y construir aligner_env.
//                - Obtener las tres virtual interfaces del config_db y
//                  propagarlas hacia los agentes.
//                - Configurar pesos y constraints por defecto (aleatorios).
//                - Ejecutar base_vseq sobre el virtual sequencer.
//
//              Los tests de corner case solo sobreescriben configure_env()
//              y/o el tipo de vseq via factory override — no replican lógica.
///////////////////////////////////////////////////////////////////////////////

class aligner_base_test extends uvm_test;
  `uvm_component_utils(aligner_base_test)

  // Environment handle
  aligner_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  // build_phase — construir env y propagar interfaces
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = aligner_env::type_id::create("env", this);

    // Aplicar configuración por defecto (overrideable por subclases)
    configure_env();
  endfunction

  // -------------------------------------------------------------------------
  // configure_env — configuración por defecto del ambiente.
  //                 Subclases llaman super.configure_env() y luego ajustan.
  // -------------------------------------------------------------------------
  virtual function void configure_env();
    // Por defecto: sin restricciones adicionales — randomización libre
    // dentro de los constraints definidos en los seq_items.
    // Los tests de corner case sobreescriben este método para ajustar
    // pesos via uvm_config_db o factory overrides.
  endfunction

  // -------------------------------------------------------------------------
  // run_phase — ejecutar la virtual sequence base
  // -------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    base_vseq vseq;

    phase.raise_objection(this);

    // Esperar a que salga el reset (20 ciclos definidos en tb_top)
    #(20 * 10ns + 1ns); // 20 ciclos × 10 ns + margen

    vseq = base_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);

    phase.drop_objection(this);
  endtask

  // -------------------------------------------------------------------------
  // report_phase — resumen final
  // -------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    if (svr.get_severity_count(UVM_FATAL) > 0 ||
        svr.get_severity_count(UVM_ERROR) > 0)
      `uvm_info("BASE_TEST",
        $sformatf("TEST FAILED — FATAL:%0d ERROR:%0d",
          svr.get_severity_count(UVM_FATAL),
          svr.get_severity_count(UVM_ERROR)), UVM_NONE)
    else
      `uvm_info("BASE_TEST", "TEST PASSED", UVM_NONE)
  endfunction

endclass : aligner_base_test