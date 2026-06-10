///////////////////////////////////////////////////////////////////////////////
// File:        irq_stress_vseq.sv
// Description: Corner case irq_stress.
//              Todos los IRQs activos y limpiados repetidamente mientras
//              las FIFOs se llenan y vacían. Alterna IRQEN.
///////////////////////////////////////////////////////////////////////////////

class irq_stress_vseq extends uvm_sequence;
  `uvm_object_utils(irq_stress_vseq)
  `uvm_declare_p_sequencer(aligner_vsequencer)

  function new(string name = "irq_stress_vseq");
    super.new(name);
  endfunction

  task body();
    apb_config_ctrl_seq     cfg_seq;
    md_rx_legal_seq         rx_seq;
    md_tx_backpressure_seq  tx_seq;
    apb_irq_clear_seq       irq_clr_seq;
    apb_write_seq           irqen_seq;
    int unsigned i;


    // Configurar DUT
    cfg_seq = apb_config_ctrl_seq::type_id::create("cfg_seq");
    cfg_seq.randomize_fields = 1'b0;
    cfg_seq.size   = 3'b001;
    cfg_seq.offset = 2'b00;
    cfg_seq.start(p_sequencer.apb_seqr);

    // Habilitar todos los IRQs al inicio
    irqen_seq = apb_write_seq::type_id::create("irqen_en");
    irqen_seq.addr = aligner_pkg::ADDR_IRQEN;
    irqen_seq.data = 32'h0000_001F;
    irqen_seq.start(p_sequencer.apb_seqr);

    // Lanzar RX y TX en background
    fork
      begin
        rx_seq = md_rx_legal_seq::type_id::create("rx_seq");
        rx_seq.n_transfers = 200;
        rx_seq.start(p_sequencer.md_rx_seqr);
      end
      begin
        tx_seq = md_tx_backpressure_seq::type_id::create("tx_seq");
        tx_seq.n_responses = 300;
        tx_seq.min_delay   = 5;
        tx_seq.max_delay   = 15;
        tx_seq.start(p_sequencer.md_tx_seqr);
      end
    join_none

    // Loop APB: limpiar IRQs y alternar IRQEN repetidamente
    repeat (30) begin
      // Limpiar todos los bits IRQ activos (W1C)
      irq_clr_seq = apb_irq_clear_seq::type_id::create("irq_clr");
      irq_clr_seq.clear_mask = 32'h0000_001F;
      irq_clr_seq.start(p_sequencer.apb_seqr);

      // Alternar IRQEN: habilitar/deshabilitar aleatoriamente
      irqen_seq = apb_write_seq::type_id::create("irqen_tog");
      irqen_seq.addr = aligner_pkg::ADDR_IRQEN;
      irqen_seq.data = $urandom_range(0, 32'h1F);
      irqen_seq.start(p_sequencer.apb_seqr);
    end

    // Restaurar IRQEN a todos habilitados al terminar
    irqen_seq = apb_write_seq::type_id::create("irqen_restore");
    irqen_seq.addr = aligner_pkg::ADDR_IRQEN;
    irqen_seq.data = 32'h0000_001F;
    irqen_seq.start(p_sequencer.apb_seqr);

    disable fork;
  endtask

endclass : irq_stress_vseq
