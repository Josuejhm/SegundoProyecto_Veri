class aligner_fifo_empty_test extends aligner_base_test;
  `uvm_component_utils(aligner_fifo_empty_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    fifo_empty_vseq vseq;
    phase.raise_objection(this);
    #(20 * 10ns + 1ns);
    vseq = fifo_empty_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : aligner_fifo_empty_test
