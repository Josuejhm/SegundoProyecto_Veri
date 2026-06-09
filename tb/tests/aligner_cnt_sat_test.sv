class aligner_cnt_sat_test extends aligner_base_test;
  `uvm_component_utils(aligner_cnt_sat_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    cnt_sat_vseq vseq;
    phase.raise_objection(this);
    #(20 * 10ns + 1ns);
    vseq = cnt_sat_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : aligner_cnt_sat_test
