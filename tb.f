// ─────────────────────────────────────────────
// tb.f — Filelist del testbench UVM
// Orden estricto de dependencias:
//   interfaces → pkg (que incluye todo lo demás) → tb_top
// ─────────────────────────────────────────────

// +incdir necesarios para que el pkg encuentre los `include
+incdir+tb
+incdir+tb/interfaces
+incdir+tb/seq_items
+incdir+tb/agents/apb
+incdir+tb/agents/md_rx
+incdir+tb/agents/md_tx
+incdir+tb/sequences/apb
+incdir+tb/sequences/md_rx
+incdir+tb/sequences/md_tx
+incdir+tb/sequences/virtual
+incdir+tb/env
+incdir+tb/tests

// Package — incluye internamente todos los archivos del TB en orden
tb/aligner_pkg.sv

// Interfaces — deben compilar antes que el pkg
tb/interfaces/apb_if.sv
tb/interfaces/md_rx_if.sv
tb/interfaces/md_tx_if.sv

// Top-level — instancia DUT, interfaces y llama run_test()
tb/tb_top.sv