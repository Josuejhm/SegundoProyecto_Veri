#!/usr/bin/env python3
###############################################################################
# fix_vseqs.py — Parchea todas las virtual sequences para usar
#                uvm_declare_p_sequencer en lugar del cast manual.
###############################################################################

import os
import re
import glob

VSEQ_DIR = "tb/sequences/virtual"

files = glob.glob(os.path.join(VSEQ_DIR, "*.sv"))
if not files:
    print(f"ERROR: No se encontraron archivos en {VSEQ_DIR}")
    exit(1)

print("══════════════════════════════════════════════════")
print(f" Parcheando {len(files)} archivos en {VSEQ_DIR}")
print("══════════════════════════════════════════════════")

for fpath in sorted(files):
    with open(fpath, "r") as f:
        content = f.read()

    original = content

    # 1. Agregar uvm_declare_p_sequencer si no está
    if "uvm_declare_p_sequencer" not in content:
        content = re.sub(
            r'(`uvm_object_utils\([^)]+\))',
            r'\1\n  `uvm_declare_p_sequencer(aligner_vsequencer)',
            content
        )

    # 2. Eliminar línea con declaración aligner_vsequencer vseqr
    content = re.sub(r'[ \t]*aligner_vsequencer\s+vseqr;\n', '', content)

    # 3. Eliminar bloque cast manual — dos líneas:
    #    if (!$cast(vseqr, m_sequencer))
    #      `uvm_fatal(...)
    content = re.sub(
        r'[ \t]*if \(!\$cast\(vseqr,\s*m_sequencer\)\)\s*\n[ \t]*`uvm_fatal[^\n]*\n',
        '',
        content
    )

    # 4. Reemplazar vseqr. por p_sequencer.
    content = content.replace("vseqr.", "p_sequencer.")

    if content != original:
        # Backup
        with open(fpath + ".bak", "w") as f:
            f.write(original)
        with open(fpath, "w") as f:
            f.write(content)
        print(f"  ✔ {os.path.basename(fpath)}")
    else:
        print(f"  ── {os.path.basename(fpath)} sin cambios")

print("\nVerificando residuos...")
residuos = []
for fpath in sorted(files):
    with open(fpath, "r") as f:
        for i, line in enumerate(f, 1):
            if "vseqr" in line:
                residuos.append(f"  {fpath}:{i}: {line.rstrip()}")

if residuos:
    print("⚠ Residuos encontrados — revisar manualmente:")
    for r in residuos:
        print(r)
else:
    print("✔ Limpio — ningún residuo de 'vseqr' encontrado")

print("══════════════════════════════════════════════════")