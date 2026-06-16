###############################################################################
# Makefile — cfs_aligner UVM environment
# Simulador : VCS M-2017.03-SP2-5
# UVM       : 1.2 (via -ntb_opts uvm-1.2)
#
# Targets principales:
#   make compile                    — compilar DUT + TB
#   make run TEST=<nombre>          — correr un test individual
#   make run_seed TEST=<n> SEED=<s> — correr con semilla fija
#   make regress                    — correr todos los corner cases
#   make corner_fifo_rx_full        — FIFO RX llena
#   make corner_fifo_tx_full        — FIFO TX llena
#   make corner_fifo_both_full      — ambas FIFOs llenas
#   make corner_fifo_empty          — FIFOs vacías
#   make corner_illegal_rx          — transfers ilegales RX
#   make corner_cnt_sat             — saturación CNT_DROP
#   make corner_apb_unmapped        — accesos APB no mapeados
#   make corner_backpressure        — backpressure severo TX
#   make cov                        — fusionar y abrir reporte de cobertura
#   make verdi                      — abrir Verdi con waves del último test
#   make clean                      — limpiar artefactos de compilación
#   make clean_results              — limpiar solo logs y resultados
#   make help                       — mostrar esta ayuda
###############################################################################

# ─────────────────────────────────────────────
# Configuración — modificar según el ambiente
# ─────────────────────────────────────────────
SYNOPSYS_TOOLS := /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools.sh

WIDTH  ?= 32
DEPTH  ?= 8
TEST   := aligner_base_test
SEED   ?= random
VERB   ?= UVM_MEDIUM
N_TX   ?= 200
PTOUT  ?= 2000

# Nombre del binario compilado
SIMV   := simv

# Directorio de resultados
RESULTS_DIR := results

# Cobertura
CM_FLAGS := -cm line+tgl+cond+fsm+branch+assert
CM_DIR   := $(SIMV).vdb

# ─────────────────────────────────────────────
# Flags de VCS
# ─────────────────────────────────────────────
VCS_FLAGS := \
    -full64 \
    -sverilog \
    -ntb_opts uvm-1.2 \
    -kdb -lca \
    -debug_acc+all \
    -debug_region+cell+encrypt \
    +lint=TFIPC-L \
	-timescale=1ns/1ps \
    +define+ALGN_DATA_WIDTH=$(WIDTH) \
    +define+FIFO_DEPTH=$(DEPTH)

# ─────────────────────────────────────────────
# Semilla para el simulador
# ─────────────────────────────────────────────
ifeq ($(SEED),random)
  SEED_FLAG :=
else
  SEED_FLAG := +ntb_random_seed=$(SEED)
endif

# ─────────────────────────────────────────────
# Lista de corner cases para regresión
# ─────────────────────────────────────────────
ALL_CORNERS := \
    corner_fifo_rx_full \
    corner_fifo_tx_full \
    corner_fifo_both_full \
    corner_fifo_empty \
    corner_illegal_rx \
    corner_cnt_sat \
    corner_apb_unmapped \
    corner_backpressure

###############################################################################
# Targets
###############################################################################

.PHONY: all compile run run_seed regress \
        $(ALL_CORNERS) \
        cov verdi clean clean_results help

all: compile

## ── Compilación ──────────────────────────────────────────────────────────────
compile: $(RESULTS_DIR)
	@echo "══════════════════════════════════════════"
	@echo " Compilando WIDTH=$(WIDTH) DEPTH=$(DEPTH)"
	@echo "══════════════════════════════════════════"
	source $(SYNOPSYS_TOOLS) && \
	vcs $(VCS_FLAGS) \
	    $(CM_FLAGS) \
	    -o $(SIMV) \
	    -f aligner.f \
	    -f tb.f \
	    -l $(RESULTS_DIR)/log_compile
	@echo "✔ Compilación exitosa → $(SIMV)"

## ── Run individual ───────────────────────────────────────────────────────────
run: $(RESULTS_DIR)
	@echo "══════════════════════════════════════════"
	@echo " Corriendo aligner_base_test  SEED=$(SEED)"
	@echo "══════════════════════════════════════════"
	source $(SYNOPSYS_TOOLS) && \
	./$(SIMV) \
	    $(CM_FLAGS) \
	    -cm_name $(TEST) \
	    +UVM_TESTNAME=$(TEST) \
	    +UVM_VERBOSITY=$(VERB) \
	    $(SEED_FLAG) \
	    +tx_min_delay=0 +tx_max_delay=0 \
	    +poll_timeout=$(PTOUT) \
	    -l $(RESULTS_DIR)/log_$(TEST)
	@echo "✔ Finalizado — log: $(RESULTS_DIR)/log_$(TEST)"

## ── Run con semilla fija (shortcut) ─────────────────────────────────────────
run_seed: $(RESULTS_DIR)
	$(MAKE) run SEED=$(SEED)

## ── Corner cases ─────────────────────────────────────────────────────────────

corner_fifo_rx_full: $(RESULTS_DIR)
	@echo "══════════════════════════════════════════"
	@echo " Corner: FIFO RX llena"
	@echo "══════════════════════════════════════════"
	source $(SYNOPSYS_TOOLS) && \
	./$(SIMV) \
	    $(CM_FLAGS) \
	    -cm_name corner_fifo_rx_full \
	    +UVM_TESTNAME=aligner_base_test \
	    +UVM_VERBOSITY=$(VERB) \
	    $(SEED_FLAG) \
	    +ctrl_randomize=0 +ctrl_size=1 +ctrl_offset=0 \
	    +rx_illegal_weight=0 \
	    +n_rx_transfers=200 \
	    +n_tx_responses=500 \
	    +tx_min_delay=80 +tx_max_delay=150 \
	    +drain_tx=0 \
	    -l $(RESULTS_DIR)/log_corner_fifo_rx_full
	@echo "✔ Finalizado — log: $(RESULTS_DIR)/log_corner_fifo_rx_full"

corner_fifo_tx_full: $(RESULTS_DIR)
	@echo "══════════════════════════════════════════"
	@echo " Corner: FIFO TX llena"
	@echo "══════════════════════════════════════════"
	source $(SYNOPSYS_TOOLS) && \
	./$(SIMV) \
	    $(CM_FLAGS) \
	    -cm_name corner_fifo_tx_full \
	    +UVM_TESTNAME=aligner_base_test \
	    +UVM_VERBOSITY=$(VERB) \
	    $(SEED_FLAG) \
	    +ctrl_randomize=0 +ctrl_size=1 +ctrl_offset=0 \
	    +rx_illegal_weight=0 \
	    +n_rx_transfers=100 \
	    +n_tx_responses=500 \
	    +tx_min_delay=200 +tx_max_delay=400 \
	    +drain_tx=0 \
	    -l $(RESULTS_DIR)/log_corner_fifo_tx_full
	@echo "✔ Finalizado — log: $(RESULTS_DIR)/log_corner_fifo_tx_full"

corner_fifo_both_full: $(RESULTS_DIR)
	@echo "══════════════════════════════════════════"
	@echo " Corner: ambas FIFOs llenas"
	@echo "══════════════════════════════════════════"
	source $(SYNOPSYS_TOOLS) && \
	./$(SIMV) \
	    $(CM_FLAGS) \
	    -cm_name corner_fifo_both_full \
	    +UVM_TESTNAME=aligner_base_test \
	    +UVM_VERBOSITY=$(VERB) \
	    $(SEED_FLAG) \
	    +ctrl_randomize=0 +ctrl_size=1 +ctrl_offset=0 \
	    +rx_illegal_weight=0 \
	    +n_rx_transfers=200 \
	    +n_tx_responses=500 \
	    +tx_min_delay=150 +tx_max_delay=300 \
	    +drain_tx=0 \
	    -l $(RESULTS_DIR)/log_corner_fifo_both_full
	@echo "✔ Finalizado — log: $(RESULTS_DIR)/log_corner_fifo_both_full"

corner_fifo_empty: $(RESULTS_DIR)
	@echo "══════════════════════════════════════════"
	@echo " Corner: FIFOs vacías"
	@echo "══════════════════════════════════════════"
	source $(SYNOPSYS_TOOLS) && \
	./$(SIMV) \
	    $(CM_FLAGS) \
	    -cm_name corner_fifo_empty \
	    +UVM_TESTNAME=aligner_base_test \
	    +UVM_VERBOSITY=$(VERB) \
	    $(SEED_FLAG) \
	    +ctrl_randomize=1 \
	    +rx_illegal_weight=0 \
	    +n_rx_transfers=50 \
	    +n_tx_responses=200 \
	    +tx_min_delay=0 +tx_max_delay=0 \
	    +poll_timeout=$(PTOUT) \
	    -l $(RESULTS_DIR)/log_corner_fifo_empty
	@echo "✔ Finalizado — log: $(RESULTS_DIR)/log_corner_fifo_empty"

corner_illegal_rx: $(RESULTS_DIR)
	@echo "══════════════════════════════════════════"
	@echo " Corner: transfers ilegales RX"
	@echo "══════════════════════════════════════════"
	source $(SYNOPSYS_TOOLS) && \
	./$(SIMV) \
	    $(CM_FLAGS) \
	    -cm_name corner_illegal_rx \
	    +UVM_TESTNAME=aligner_base_test \
	    +UVM_VERBOSITY=$(VERB) \
	    $(SEED_FLAG) \
	    +ctrl_randomize=0 +ctrl_size=1 +ctrl_offset=0 \
	    +rx_illegal_weight=100 \
	    +n_rx_transfers=150 \
	    +n_tx_responses=200 \
	    +tx_min_delay=0 +tx_max_delay=3 \
	    +poll_timeout=$(PTOUT) \
	    -l $(RESULTS_DIR)/log_corner_illegal_rx
	@echo "✔ Finalizado — log: $(RESULTS_DIR)/log_corner_illegal_rx"

corner_cnt_sat: $(RESULTS_DIR)
	@echo "══════════════════════════════════════════"
	@echo " Corner: saturación CNT_DROP"
	@echo "══════════════════════════════════════════"
	source $(SYNOPSYS_TOOLS) && \
	./$(SIMV) \
	    $(CM_FLAGS) \
	    -cm_name corner_cnt_sat \
	    +UVM_TESTNAME=aligner_base_test \
	    +UVM_VERBOSITY=$(VERB) \
	    $(SEED_FLAG) \
	    +ctrl_randomize=0 +ctrl_size=1 +ctrl_offset=0 \
	    +rx_illegal_weight=100 \
	    +n_rx_transfers=260 \
	    +n_tx_responses=500 \
	    +tx_min_delay=0 +tx_max_delay=3 \
	    +poll_timeout=$(PTOUT) \
	    -l $(RESULTS_DIR)/log_corner_cnt_sat
	@echo "✔ Finalizado — log: $(RESULTS_DIR)/log_corner_cnt_sat"

corner_apb_unmapped: $(RESULTS_DIR)
	@echo "══════════════════════════════════════════"
	@echo " Corner: accesos APB no mapeados"
	@echo "══════════════════════════════════════════"
	source $(SYNOPSYS_TOOLS) && \
	./$(SIMV) \
	    $(CM_FLAGS) \
	    -cm_name corner_apb_unmapped \
	    +UVM_TESTNAME=aligner_base_test \
	    +UVM_VERBOSITY=$(VERB) \
	    $(SEED_FLAG) \
	    +ctrl_randomize=1 \
	    +rx_illegal_weight=0 \
	    +n_rx_transfers=40 \
	    +n_apb_txns=50 \
	    +n_tx_responses=200 \
	    +tx_min_delay=0 +tx_max_delay=3 \
	    +unmapped_only=1 \
	    +drain_tx=0 +allow_pending_tx=1 \
	    -l $(RESULTS_DIR)/log_corner_apb_unmapped
	@echo "✔ Finalizado — log: $(RESULTS_DIR)/log_corner_apb_unmapped"

corner_backpressure: $(RESULTS_DIR)
	@echo "══════════════════════════════════════════"
	@echo " Corner: backpressure severo TX"
	@echo "══════════════════════════════════════════"
	source $(SYNOPSYS_TOOLS) && \
	./$(SIMV) \
	    $(CM_FLAGS) \
	    -cm_name corner_backpressure \
	    +UVM_TESTNAME=aligner_base_test \
	    +UVM_VERBOSITY=$(VERB) \
	    $(SEED_FLAG) \
	    +ctrl_randomize=0 +ctrl_size=4 +ctrl_offset=0 \
	    +rx_illegal_weight=0 \
	    +n_rx_transfers=100 \
	    +n_tx_responses=200 \
	    +tx_min_delay=10 +tx_max_delay=50 \
	    +drain_tx=0 +allow_pending_tx=1 \
	    -l $(RESULTS_DIR)/log_corner_backpressure
	@echo "✔ Finalizado — log: $(RESULTS_DIR)/log_corner_backpressure"

## ── Regresión completa (todos los corner cases) ──────────────────────────────
regress: $(RESULTS_DIR)
	@echo "══════════════════════════════════════════"
	@echo " Regresión — $(words $(ALL_CORNERS)) corner cases"
	@echo "══════════════════════════════════════════"
	@PASS=0; FAIL=0; \
	for t in $(ALL_CORNERS); do \
	    echo "── $$t ──"; \
	    $(MAKE) $$t; \
	    if grep -q "TEST PASSED" $(RESULTS_DIR)/log_$$t; then \
	        PASS=$$((PASS+1)); echo "  ✔ PASSED"; \
	    else \
	        FAIL=$$((FAIL+1)); echo "  ✘ FAILED"; \
	    fi; \
	done; \
	echo "══════════════════════════════════════════"; \
	echo " Resultados: $$PASS PASSED  $$FAIL FAILED"; \
	echo "══════════════════════════════════════════"

## ── Reporte de cobertura ─────────────────────────────────────────────────────
cov:
	@echo "Fusionando bases de cobertura..."
	source $(SYNOPSYS_TOOLS) && \
	urg -dir $(CM_DIR) -report $(RESULTS_DIR)/cov_report -format both
	@echo "✔ Reporte en $(RESULTS_DIR)/cov_report"

## ── Abrir Verdi ──────────────────────────────────────────────────────────────
verdi:
	source $(SYNOPSYS_TOOLS) && \
	verdi -cov -covdir $(CM_DIR) &

## ── Directorio de resultados ─────────────────────────────────────────────────
$(RESULTS_DIR):
	mkdir -p $(RESULTS_DIR)

## ── Limpieza ─────────────────────────────────────────────────────────────────
clean:
	rm -rf $(SIMV) $(SIMV).daidir csrc $(CM_DIR) \
	       AN.DB DVEfiles ucli.key *.key *.log \
	       $(RESULTS_DIR)
	@echo "✔ Limpieza completa"

clean_results:
	rm -rf $(RESULTS_DIR)
	@echo "✔ Resultados eliminados"

## ── Ayuda ────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  Targets disponibles:"
	@echo "    compile                  Compilar DUT + TB"
	@echo "    run                      Correr el test base (semilla aleatoria)"
	@echo "    run_seed SEED=<s>        Correr el test base con semilla fija"
	@echo "    regress                  Correr todos los corner cases"
	@echo "    corner_fifo_rx_full      FIFO RX llena"
	@echo "    corner_fifo_tx_full      FIFO TX llena"
	@echo "    corner_fifo_both_full    Ambas FIFOs llenas"
	@echo "    corner_fifo_empty        FIFOs vacías"
	@echo "    corner_illegal_rx        Transfers ilegales RX"
	@echo "    corner_cnt_sat           Saturación CNT_DROP"
	@echo "    corner_apb_unmapped      Accesos APB no mapeados"
	@echo "    corner_backpressure      Backpressure severo TX"
	@echo "    cov                      Generar reporte de cobertura"
	@echo "    verdi                    Abrir Verdi con waves"
	@echo "    clean                    Eliminar todos los artefactos"
	@echo "    clean_results            Eliminar solo resultados/logs"
	@echo ""
	@echo "  Variables configurables:"
	@echo "    WIDTH  = $(WIDTH)  (ALGN_DATA_WIDTH: 8|16|32|64)"
	@echo "    DEPTH  = $(DEPTH)   (FIFO_DEPTH: 2|8|16)"
	@echo "    VERB   = $(VERB)"
	@echo ""
	@echo "  Ejemplos:"
	@echo "    make compile WIDTH=64 DEPTH=16"
	@echo "    make run"
	@echo "    make run_seed SEED=12345"
	@echo "    make corner_fifo_rx_full"
	@echo "    make corner_backpressure SEED=12345"
	@echo "    make regress"
	@echo ""
