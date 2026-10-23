#!/usr/bin/env python3
"""Capture this environment's actual verification attempts; never invent PASS."""
import json
import os
from pathlib import Path
import shlex
import subprocess

root = Path(__file__).resolve().parents[1]
os.chdir(root)
(root/'logs').mkdir(exist_ok=True)
commands = [
    ['python3','scripts/check_sources.py'],
    ['make','programs'],
    ['python3','scripts/run_tests.py','unit'],
    ['python3','scripts/run_tests.py','core'],
    ['python3','scripts/run_tests.py','lint'],
    ['iverilog','-g2012','-Wall','-s','tb_alu','-o','build/tb_alu.vvp',
     '-f','rtl/files.f','tb/tb_alu.sv'],
    ['vvp','build/tb_alu.vvp'],
    ['verilator','--lint-only','-Wall','--top-module','riscv_core','-f','rtl/files.f'],
]
results=[]
with (root/'logs/execution.txt').open('w') as log:
    for command in commands:
        try:
            p=subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            code,output=p.returncode,p.stdout
        except FileNotFoundError:
            code,output=127,f'{command[0]}: executable not found on PATH\n'
        entry={'command':shlex.join(command),'exit_code':code,'output':output}
        results.append(entry)
        text=f"$ {entry['command']}\n{output}[exit {code}]\n\n"
        print(text,end=''); log.write(text)
(root/'logs/execution.json').write_text(json.dumps(results,indent=2)+'\n')
