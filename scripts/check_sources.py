#!/usr/bin/env python3
"""Local packaging checks only: NOT an HDL compiler, simulator, or lint substitute."""
import ast
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
for script in sorted((root/'scripts').glob('*.py')):
    ast.parse(script.read_text(), filename=str(script))
    print(f'PASS Python syntax: {script.relative_to(root)}')
rtl_files = (root/'rtl/files.f').read_text().splitlines()
for filename in rtl_files:
    assert (root/filename).is_file(), filename
    text = (root/filename).read_text()
    assert 'lint_off' not in text, filename
    assert text.count('endmodule') == (0 if filename.endswith('rv32i_pkg.sv') else 1), filename
assert len(rtl_files) == 11
print('PASS RTL file-list completeness (11 files); no lint suppression pragmas')
cases = json.loads((root/'programs/fault_cases.json').read_text())
assert [c['id'] for c in cases] == list(range(20))
assert all(1 <= c['cause'] <= 7 for c in cases)
print('PASS fault-case manifest (20 cases)')
for filename in ('sum.S','isa.S','imm_vectors.S','faults.S'):
    text = (root/'programs'/filename).read_text()
    # Immediate fixture words are expected-value data, not manual machine code.
    if filename != 'imm_vectors.S':
        assert '.word' not in text and '.insn' not in text
print('PASS no hand-encoded instructions in assembly sources')
print('NOTE: these checks do not validate SystemVerilog or instruction execution')
