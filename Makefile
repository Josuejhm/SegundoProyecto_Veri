###############################################################################
# Makefile — cfs_aligner UVM environment
# Simulador : VCS M-2017.03-SP2-5
# UVM       : 1.2 (via -ntb_opts uvm-1.2)
#
# Targets:
#   make compile              — compilar DUT + TB
#   make run TEST=<nombre>    — correr un test
#   make run_seed TEST=<n> SEED=<s> — correr con semilla fija
#   make regress              — correr todos los tests
#   make cov                  — fusionar y abrir reporte de cobertura
#   make verdi                — abrir Verdi con waves del último test
#   make clean                — limpiar artefactos de compilación
#   make clean_results        — limpiar solo logs y resultados
#   make help                 — mostrar esta ayuda
###############################################################################

# ─────────────────────────────────────────────
# Configuración — modificar según el ambiente
# ─────────────────────────────────────────────
SYNOPSYS_TOOLS := /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools.sh

WIDTH  ?= 32
DEPTH  ?= 8
TEST   ?= aligner_base_test
SEED   ?= random
VERB   ?= UVM_MEDIUM

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
# Lista de todos los tests para regresión
# ─────────────────────────────────────────────
ALL_TESTS := \
    aligner_base_test \
    aligner_fifo_rx_full_test \
    aligner_fifo_tx_full_test \
    aligner_fifo_both_full_test \
    aligner_fifo_empty_test \
    aligner_illegal_rx_test \
    aligner_cnt_sat_test \
    aligner_apb_unmapped_test \
    aligner_apb_illegal_ctrl_test \
    aligner_irq_stress_test \
    aligner_backpressure_test

###############################################################################
# Targets
###############################################################################

.PHONY: all compile run run_seed regress cov verdi clean clean_results help

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
	@echo " Corriendo TEST=$(TEST)  SEED=$(SEED)"
	@echo "══════════════════════════════════════════"
	source $(SYNOPSYS_TOOLS) && \
	./$(SIMV) \
	    $(CM_FLAGS) \
	    -cm_name $(TEST) \
	    +UVM_TESTNAME=$(TEST) \
	    +UVM_VERBOSITY=$(VERB) \
	    $(SEED_FLAG) \
	    -l $(RESULTS_DIR)/log_$(TEST)
	@echo "✔ Finalizado — log: $(RESULTS_DIR)/log_$(TEST)"

## ── Run con semilla fija (shortcut) ─────────────────────────────────────────
run_seed: $(RESULTS_DIR)
	$(MAKE) run TEST=$(TEST) SEED=$(SEED)

## ── Regresión completa ───────────────────────────────────────────────────────
regress: $(RESULTS_DIR)
	@echo "══════════════════════════════════════════"
	@echo " Regresión completa — $(words $(ALL_TESTS)) tests"
	@echo "══════════════════════════════════════════"
	@PASS=0; FAIL=0; \
	for t in $(ALL_TESTS); do \
	    echo "── $$t ──"; \
	    source $(SYNOPSYS_TOOLS) && \
	    ./$(SIMV) \
	        $(CM_FLAGS) \
	        -cm_name $$t \
	        +UVM_TESTNAME=$$t \
	        +UVM_VERBOSITY=$(VERB) \
	        -l $(RESULTS_DIR)/log_$$t ; \
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
	@echo "    run TEST=<test>          Correr un test (semilla aleatoria)"
	@echo "    run_seed TEST=<t> SEED=<s>  Correr con semilla fija"
	@echo "    regress                  Correr todos los tests"
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
	@echo "    make run TEST=aligner_fifo_rx_full_test"
	@echo "    make run_seed TEST=aligner_base_test SEED=12345"
	@echo "    make regress"
	@echo ""