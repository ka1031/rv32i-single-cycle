#!/usr/bin/env python3
"""Run units before core tests; every subprocess and actual result is logged."""
import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
(ROOT/'build').mkdir(exist_ok=True)
(ROOT/'logs').mkdir(exist_ok=True)


def run(args, log):
    command = '+ ' + shlex.join(map(str, args)) + '\n'
    print(command, end='', flush=True)
    log.write(command); log.flush()
    p = subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(p.stdout, end='', flush=True)
    log.write(p.stdout + f'[exit {p.returncode}]\n'); log.flush()
    if p.returncode:
        raise RuntimeError(f'Command failed with exit {p.returncode}')
    return p.stdout


def simulate(top, name, log, params=None, plusargs=()):
    exe = f'build/{name}.vvp'
    args = ['iverilog', '-g2012', '-Wall', '-s', top, '-o', exe, '-f', 'rtl/files.f', f'tb/{top}.sv']
    for key, value in (params or {}).items():
        args += [f'-P{top}.{key}={value}']
    run(args, log)
    output = run(['vvp', exe, *plusargs], log)
    if 'PASS ' not in output or 'FAIL ' in output:
        raise RuntimeError('Simulator did not report unambiguous PASS')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['unit', 'core', 'all', 'lint'])
    args = parser.parse_args()
    with Path(f'logs/{args.mode}.log').open('w') as log:
        needed = ['verilator'] if args.mode == 'lint' else ['iverilog', 'vvp']
        for tool in needed:
            if not shutil.which(tool):
                log.write(f'BLOCKED: {tool} is not installed / not on PATH\n')
                raise RuntimeError(f'{tool} is not installed / not on PATH')
        if args.mode == 'lint':
            # No -Wno-*, no -Wno-fatal, and no source lint suppression pragmas.
            run(['verilator', '--version'], log)
            output = run(['verilator', '--lint-only', '-Wall', '--top-module', 'riscv_core',
                         '-f', 'rtl/files.f'], log)
            if '%Warning' in output:
                raise RuntimeError('RTL warnings remain')
            for top in ['tb_alu','tb_regfile','tb_imm_gen','tb_branch_unit','tb_data_mem',
                        'tb_fault_unit','tb_core','tb_faults']:
                output = run(['verilator','--lint-only','--timing','-Wall',
                              '--top-module',top,'-f','rtl/files.f',f'tb/{top}.sv'],log)
                if '%Warning' in output:
                    raise RuntimeError(f'{top}: warnings remain')
            print('PASS Verilator -Wall (RTL and all testbenches)')
            log.write('PASS Verilator -Wall (RTL and all testbenches)\n')
            return
        run(['iverilog','-V'],log)
        run(['vvp','-V'],log)
        if args.mode in ('unit','all'):
            for top in ['tb_alu','tb_regfile','tb_imm_gen','tb_branch_unit','tb_data_mem','tb_fault_unit']:
                simulate(top,top,log)
        if args.mode in ('core','all'):
            simulate('tb_core','sum',log,plusargs=['+VCD=build/sum.vcd'])
            simulate('tb_core','isa',log,{'HEX_FILE':'"programs/isa.hex"','CHECK_SUM':'0'},
                     ['+VCD=build/isa.vcd'])
            for case in json.loads(Path('build/fault_manifest.json').read_text()):
                print(f"Case {case['id']}: {case['name']}",flush=True)
                simulate('tb_faults',f"fault_{case['id']}",log,
                         {'HEX_FILE':json.dumps(case['hex']), 'EXPECT_CAUSE':case['cause'],
                          'EXPECT_PC':case['pc'], 'EXPECT_A0':case['a0']})
        print(f'PASS regression mode={args.mode}')
        log.write(f'PASS regression mode={args.mode}\n')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, ValueError) as exc:
        print(f'FAIL run_tests: {exc}',file=sys.stderr)
        sys.exit(1)
