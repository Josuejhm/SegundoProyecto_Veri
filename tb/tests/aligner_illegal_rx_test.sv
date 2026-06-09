class aligner_illegal_rx_test extends aligner_base_test;
  `uvm_component_utils(aligner_illegal_rx_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    illegal_rx_vseq vseq;
    phase.raise_objection(this);
    #(20 * 10ns + 1ns);
    vseq = illegal_rx_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : aligner_illegal_rx_test
