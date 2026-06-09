class aligner_backpressure_test extends aligner_base_test;
  `uvm_component_utils(aligner_backpressure_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    backpressure_vseq vseq;
    phase.raise_objection(this);
    #(20 * 10ns + 1ns);
    vseq = backpressure_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : aligner_backpressure_test
