///////////////////////////////////////////////////////////////////////////////
// File:        aligner_coverage.sv
// Description: Coverage collector para el ambiente cfs_aligner.
//              Hereda de uvm_component e implementa los tres analysis imports
//              para recibir transacciones de los tres monitores.
//
//              Covergroups implementados:
//                cg_ctrl_config   — combinaciones legales de SIZE × OFFSET
//                cg_rx_transfer   — espacio de transfers MD RX
//                cg_fifo_levels   — niveles RX_LVL × TX_LVL
//                cg_cnt_drop      — estados del contador de drops
//                cg_apb_access    — accesos APB por registro y tipo
//                cg_irq           — comportamiento de cada IRQ
//                cg_backpressure  — duración del backpressure TX
///////////////////////////////////////////////////////////////////////////////

`uvm_analysis_imp_decl(_apb_cov)
`uvm_analysis_imp_decl(_md_rx_cov)
`uvm_analysis_imp_decl(_md_tx_cov)

class aligner_coverage extends uvm_component;
  `uvm_component_utils(aligner_coverage)

  // -------------------------------------------------------------------------
  // Analysis imports
  // -------------------------------------------------------------------------
  uvm_analysis_imp_apb_cov   #(apb_seq_item,   aligner_coverage) apb_export;
  uvm_analysis_imp_md_rx_cov #(md_rx_seq_item, aligner_coverage) md_rx_export;
  uvm_analysis_imp_md_tx_cov #(md_tx_seq_item, aligner_coverage) md_tx_export;

  // -------------------------------------------------------------------------
  // Estado interno — actualizado por los write_* y usado por los covergroups
  // -------------------------------------------------------------------------
  bit [2:0]  curr_size     = 3'b001;
  bit [1:0]  curr_offset   = 2'b00;
  bit [7:0]  curr_cnt_drop = 8'h00;
  bit [3:0]  curr_rx_lvl   = 4'h0;
  bit [3:0]  curr_tx_lvl   = 4'h0;
  bit [4:0]  curr_irq      = 5'h00;
  bit [4:0]  curr_irqen    = 5'h1F; // reset value según RTL

  // Contexto para cg_apb_access
  typedef enum logic [2:0] {
    CTRL_REG    = 3'd0,
    STATUS_REG  = 3'd1,
    IRQEN_REG   = 3'd2,
    IRQ_REG     = 3'd3,
    UNMAPPED_REG= 3'd4
  } reg_e;

  reg_e  curr_reg;
  bit    curr_write;
  bit    curr_slverr;
  bit [1:0] curr_addr_lsb;

  // Contexto para cg_rx_transfer
  bit curr_rx_is_legal;
  bit curr_rx_err;

  // Contexto para cg_backpressure
  int unsigned curr_ready_delay;

  // -------------------------------------------------------------------------
  // Covergroup: cg_ctrl_config
  // Cubre combinaciones legales de SIZE × OFFSET escritas exitosamente.
  // -------------------------------------------------------------------------
  covergroup cg_ctrl_config;
    cp_size: coverpoint curr_size {
      bins size_1 = {3'd1};
      bins size_2 = {3'd2};
      bins size_3 = {3'd3};
      bins size_4 = {3'd4};
      // Para ALGN_DATA_WIDTH=64 también aplican 5,6,7,8
      // pero los bins adicionales se agregan si es necesario
    }
    cp_offset: coverpoint curr_offset {
      bins offset_0 = {2'd0};
      bins offset_1 = {2'd1};
      bins offset_2 = {2'd2};
      bins offset_3 = {2'd3};
    }
    cx_size_offset: cross cp_size, cp_offset;
    // Nota: las combinaciones ilegales nunca se muestrean porque solo
    // se muestrea tras un write exitoso (pslverr=0)
  endgroup

  // -------------------------------------------------------------------------
  // Covergroup: cg_rx_transfer
  // Cubre el espacio de transfers MD RX.
  // -------------------------------------------------------------------------
  covergroup cg_rx_transfer;
    cp_legal: coverpoint curr_rx_is_legal {
      bins legal   = {1'b1};
      bins illegal = {1'b0};
    }
    cp_err: coverpoint curr_rx_err {
      bins no_err = {1'b0};
      bins err    = {1'b1};
    }
    cx_legal_err: cross cp_legal, cp_err;
  endgroup

  // -------------------------------------------------------------------------
  // Covergroup: cg_fifo_levels
  // Cubre niveles de llenado de ambas FIFOs leídos en STATUS.
  // -------------------------------------------------------------------------
  covergroup cg_fifo_levels;
    cp_rx_lvl: coverpoint curr_rx_lvl {
      bins empty   = {4'd0};
      bins partial = {[4'd1 : aligner_pkg::FIFO_DEPTH - 1]};
      bins full    = {aligner_pkg::FIFO_DEPTH};
    }
    cp_tx_lvl: coverpoint curr_tx_lvl {
      bins empty   = {4'd0};
      bins partial = {[4'd1 : aligner_pkg::FIFO_DEPTH - 1]};
      bins full    = {aligner_pkg::FIFO_DEPTH};
    }
    cx_levels: cross cp_rx_lvl, cp_tx_lvl;
  endgroup

  // -------------------------------------------------------------------------
  // Covergroup: cg_cnt_drop
  // Cubre estados del contador de drops.
  // -------------------------------------------------------------------------
  covergroup cg_cnt_drop;
    cp_cnt: coverpoint curr_cnt_drop {
      bins zero    = {8'd0};
      bins middle  = {[8'd1 : 8'd254]};
      bins max_val = {8'd255};
    }
  endgroup

  // -------------------------------------------------------------------------
  // Covergroup: cg_apb_access
  // Cubre accesos APB por registro, tipo y pslverr.
  // -------------------------------------------------------------------------
  covergroup cg_apb_access;
    cp_reg: coverpoint curr_reg {
      bins ctrl     = {CTRL_REG};
      bins status   = {STATUS_REG};
      bins irqen    = {IRQEN_REG};
      bins irq_reg  = {IRQ_REG};
      bins unmapped = {UNMAPPED_REG};
    }
    cp_type: coverpoint curr_write {
      bins read  = {1'b0};
      bins write = {1'b1};
    }
    cp_slverr: coverpoint curr_slverr {
      bins no_err = {1'b0};
      bins err    = {1'b1};
    }
    cp_addr_lsb: coverpoint curr_addr_lsb {
      bins lsb_00 = {2'b00};
      bins lsb_01 = {2'b01};
      bins lsb_10 = {2'b10};
      bins lsb_11 = {2'b11};
    }
    cx_access: cross cp_reg, cp_type, cp_slverr;
  endgroup

  // -------------------------------------------------------------------------
  // Covergroup: cg_irq
  // Cubre el estado de cada bit IRQ con su correspondiente IRQEN.
  // -------------------------------------------------------------------------
  covergroup cg_irq;
    // RX_FIFO_EMPTY
    cp_rx_empty_irq:  coverpoint curr_irq[aligner_pkg::IRQ_RX_FIFO_EMPTY_BIT];
    cp_rx_empty_en:   coverpoint curr_irqen[aligner_pkg::IRQ_RX_FIFO_EMPTY_BIT];
    cx_rx_empty: cross cp_rx_empty_irq, cp_rx_empty_en;

    // RX_FIFO_FULL
    cp_rx_full_irq:   coverpoint curr_irq[aligner_pkg::IRQ_RX_FIFO_FULL_BIT];
    cp_rx_full_en:    coverpoint curr_irqen[aligner_pkg::IRQ_RX_FIFO_FULL_BIT];
    cx_rx_full: cross cp_rx_full_irq, cp_rx_full_en;

    // TX_FIFO_EMPTY
    cp_tx_empty_irq:  coverpoint curr_irq[aligner_pkg::IRQ_TX_FIFO_EMPTY_BIT];
    cp_tx_empty_en:   coverpoint curr_irqen[aligner_pkg::IRQ_TX_FIFO_EMPTY_BIT];
    cx_tx_empty: cross cp_tx_empty_irq, cp_tx_empty_en;

    // TX_FIFO_FULL
    cp_tx_full_irq:   coverpoint curr_irq[aligner_pkg::IRQ_TX_FIFO_FULL_BIT];
    cp_tx_full_en:    coverpoint curr_irqen[aligner_pkg::IRQ_TX_FIFO_FULL_BIT];
    cx_tx_full: cross cp_tx_full_irq, cp_tx_full_en;

    // MAX_DROP — bug: irq pin nunca pulsa para este evento
    cp_max_drop_irq:  coverpoint curr_irq[aligner_pkg::IRQ_MAX_DROP_BIT];
    cp_max_drop_en:   coverpoint curr_irqen[aligner_pkg::IRQ_MAX_DROP_BIT];
    cx_max_drop: cross cp_max_drop_irq, cp_max_drop_en;

    // Múltiples IRQs activos simultáneamente
    cp_multi_irq: coverpoint curr_irq {
      bins none       = {5'b00000};
      bins single     = {5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b10000};
      bins multiple   = default;
    }
  endgroup

  // -------------------------------------------------------------------------
  // Covergroup: cg_backpressure
  // Cubre la duración del backpressure en TX.
  // -------------------------------------------------------------------------
  covergroup cg_backpressure;
    cp_delay: coverpoint curr_ready_delay {
      bins one_cycle   = {1};
      bins few_cycles  = {[2:5]};
      bins many_cycles = {[6:$]};
    }
  endgroup

  // -------------------------------------------------------------------------
  // Constructor — instanciar covergroups
  // -------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_ctrl_config  = new();
    cg_rx_transfer  = new();
    cg_fifo_levels  = new();
    cg_cnt_drop     = new();
    cg_apb_access   = new();
    cg_irq          = new();
    cg_backpressure = new();
  endfunction

  // -------------------------------------------------------------------------
  // build_phase
  // -------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_export    = new("apb_export",    this);
    md_rx_export  = new("md_rx_export",  this);
    md_tx_export  = new("md_tx_export",  this);
  endfunction

  // =========================================================================
  // write_apb_cov — llamado por el monitor APB
  // =========================================================================
  function void write_apb_cov(apb_seq_item item);

    // Determinar el registro accedido
    case (item.addr & 16'hFFFC) // ignorar bits [1:0]
      aligner_pkg::ADDR_CTRL:   curr_reg = CTRL_REG;
      aligner_pkg::ADDR_STATUS: curr_reg = STATUS_REG;
      aligner_pkg::ADDR_IRQEN:  curr_reg = IRQEN_REG;
      aligner_pkg::ADDR_IRQ:    curr_reg = IRQ_REG;
      default:                  curr_reg = UNMAPPED_REG;
    endcase

    curr_write    = item.write;
    curr_slverr   = item.slverr;
    curr_addr_lsb = item.addr[1:0];
    cg_apb_access.sample();

    // Actualizar estado a partir de lecturas
    if (!item.write && !item.slverr) begin

      if (item.addr == aligner_pkg::ADDR_STATUS) begin
        curr_cnt_drop = item.rdata[aligner_pkg::STATUS_CNT_DROP_MSB :
                                   aligner_pkg::STATUS_CNT_DROP_LSB];
        curr_rx_lvl   = item.rdata[aligner_pkg::STATUS_RX_LVL_MSB :
                                   aligner_pkg::STATUS_RX_LVL_LSB];
        curr_tx_lvl   = item.rdata[aligner_pkg::STATUS_TX_LVL_MSB :
                                   aligner_pkg::STATUS_TX_LVL_LSB];
        cg_fifo_levels.sample();
        cg_cnt_drop.sample();
      end

      if (item.addr == aligner_pkg::ADDR_IRQ) begin
        curr_irq = item.rdata[4:0];
        cg_irq.sample();
      end

      if (item.addr == aligner_pkg::ADDR_IRQEN) begin
        curr_irqen = item.rdata[4:0];
        cg_irq.sample();
      end
    end

    // Actualizar CTRL tras write exitoso
    if (item.write && !item.slverr && item.addr == aligner_pkg::ADDR_CTRL) begin
      curr_size   = item.wdata[aligner_pkg::CTRL_SIZE_MSB :
                               aligner_pkg::CTRL_SIZE_LSB];
      curr_offset = item.wdata[aligner_pkg::CTRL_OFFSET_MSB :
                               aligner_pkg::CTRL_OFFSET_LSB];
      cg_ctrl_config.sample();

      // Si CLR=1, muestrear cg_cnt_drop (CNT_DROP vuelve a 0)
      if (item.wdata[aligner_pkg::CTRL_CLR_BIT]) begin
        curr_cnt_drop = 8'd0;
        cg_cnt_drop.sample();
      end
    end

    if (item.write && !item.slverr && item.addr == aligner_pkg::ADDR_IRQEN) begin
      curr_irqen = item.wdata[4:0];
    end

  endfunction : write_apb_cov

  // =========================================================================
  // write_md_rx_cov — llamado por el monitor MD RX
  // =========================================================================
  function void write_md_rx_cov(md_rx_seq_item item);
    curr_rx_is_legal = !(item.size == 0 ||
      (((aligner_pkg::ALGN_DATA_WIDTH / 8) + item.offset) % item.size != 0));
    curr_rx_err = item.err_captured;
    cg_rx_transfer.sample();
  endfunction : write_md_rx_cov

  // =========================================================================
  // write_md_tx_cov — llamado por el monitor MD TX
  // =========================================================================
  function void write_md_tx_cov(md_tx_seq_item item);
    curr_ready_delay = item.ready_delay;
    if (item.ready_delay > 0)
      cg_backpressure.sample();
  endfunction : write_md_tx_cov

endclass : aligner_coverage
