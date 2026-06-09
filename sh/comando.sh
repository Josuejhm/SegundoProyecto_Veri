#!/bin/bash
source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools.sh

# Limpiar archivos generados anteriores (conserva .sv, .v y .sh)
rm -rfv `ls | grep -v ".*\.sv\|.*\.v\|.*\.sh"`

# ─────────────────────────────────────────────
# Parámetros del DUT
# ─────────────────────────────────────────────
DEPTH=8
WIDTH=32

# ─────────────────────────────────────────────
# Compilación
# ─────────────────────────────────────────────
vcs -Mupdate tb/tb_top.sv \
    -o salida \
    -full64 -sverilog \
    -ntb_opts uvm-1.2 \
    -kdb -lca \
    -debug_acc+all -debug_region+cell+encrypt \
    -l log_compile \
    +lint=TFIPC-L \
    -cm line+tgl+cond+fsm+branch+assert \
    +incdir+tb +incdir+tb/interfaces \
    +define+ALGN_DATA_WIDTH=${WIDTH} \
    +define+FIFO_DEPTH=${DEPTH}

echo "Compilado con ALGN_DATA_WIDTH=${WIDTH} FIFO_DEPTH=${DEPTH}"

# ─────────────────────────────────────────────
# Tests — descomentar el deseado
# ─────────────────────────────────────────────

# Test base (aleatorio general)
./salida -cm line+tgl+cond+fsm+branch+assert \
         +UVM_TESTNAME=aligner_base_test \
         +UVM_VERBOSITY=UVM_MEDIUM \
         -l log_base

# Para reproducir con semilla específica:
#./salida -cm line+tgl+cond+fsm+branch+assert \
#         +UVM_TESTNAME=aligner_base_test \
#         +UVM_VERBOSITY=UVM_MEDIUM \
#         +ntb_random_seed=12345 \
#         -l log_base_seed

# RX FIFO llena — producer RX rápido, TX acepta lento
#./salida -cm line+tgl+cond+fsm+branch+assert \
#         +UVM_TESTNAME=aligner_fifo_rx_full_test \
#         +UVM_VERBOSITY=UVM_MEDIUM \
#         -l log_fifo_rx_full

# TX FIFO llena — TX casi siempre bloqueado
#./salida -cm line+tgl+cond+fsm+branch+assert \
#         +UVM_TESTNAME=aligner_fifo_tx_full_test \
#         +UVM_VERBOSITY=UVM_MEDIUM \
#         -l log_fifo_tx_full

# Ambas FIFOs llenas simultáneamente
#./salida -cm line+tgl+cond+fsm+branch+assert \
#         +UVM_TESTNAME=aligner_fifo_both_full_test \
#         +UVM_VERBOSITY=UVM_MEDIUM \
#         -l log_fifo_both_full

# FIFOs vacías — RX lento, TX acepta inmediatamente
#./salida -cm line+tgl+cond+fsm+branch+assert \
#         +UVM_TESTNAME=aligner_fifo_empty_test \
#         +UVM_VERBOSITY=UVM_MEDIUM \
#         -l log_fifo_empty

# Transfers RX ilegales — satura CNT_DROP
#./salida -cm line+tgl+cond+fsm+branch+assert \
#         +UVM_TESTNAME=aligner_illegal_rx_test \
#         +UVM_VERBOSITY=UVM_MEDIUM \
#         -l log_illegal_rx

# Saturación de CNT_DROP cerca de 255 y ejercicio de CLR
#./salida -cm line+tgl+cond+fsm+branch+assert \
#         +UVM_TESTNAME=aligner_cnt_sat_test \
#         +UVM_VERBOSITY=UVM_MEDIUM \
#         -l log_cnt_sat

# Accesos APB a direcciones no mapeadas
#./salida -cm line+tgl+cond+fsm+branch+assert \
#         +UVM_TESTNAME=aligner_apb_unmapped_test \
#         +UVM_VERBOSITY=UVM_MEDIUM \
#         -l log_apb_unmapped

# Escrituras ilegales al registro CTRL
#./salida -cm line+tgl+cond+fsm+branch+assert \
#         +UVM_TESTNAME=aligner_apb_illegal_ctrl_test \
#         +UVM_VERBOSITY=UVM_MEDIUM \
#         -l log_apb_illegal_ctrl

# Estrés de IRQs — todos los bits activos y limpiados repetidamente
#./salida -cm line+tgl+cond+fsm+branch+assert \
#         +UVM_TESTNAME=aligner_irq_stress_test \
#         +UVM_VERBOSITY=UVM_MEDIUM \
#         -l log_irq_stress

# Backpressure severo en TX
#./salida -cm line+tgl+cond+fsm+branch+assert \
#         +UVM_TESTNAME=aligner_backpressure_test \
#         +UVM_VERBOSITY=UVM_MEDIUM \
#         -l log_backpressure

# ─────────────────────────────────────────────
# Ver cobertura en Verdi
# ─────────────────────────────────────────────
verdi -cov -covdir salida.vdb &
