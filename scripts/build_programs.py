#!/usr/bin/env python3
"""Build every instruction with GNU binutils; serialize objcopy bytes for readmemh."""
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
BUILD = ROOT / 'build'
BUILD.mkdir(exist_ok=True)
CROSS = os.environ.get('CROSS', 'riscv32-unknown-elf-')
TOOLS = {name: CROSS + name for name in ('as', 'ld', 'objcopy', 'objdump', 'nm')}


def run(args):
    print('+ ' + shlex.join(map(str, args)), flush=True)
    result = subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result.stdout:
        print(result.stdout, end='', flush=True)
    if result.returncode:
        raise RuntimeError(f'exit {result.returncode}: {args[0]}')
    return result.stdout


def bin_to_hex(source, dest, pad_words=None):
    data = source.read_bytes()
    if len(data) % 4:
        raise ValueError(f'{source}: not a whole number of RV32I words')
    if pad_words is not None:
        if len(data) > 4 * pad_words:
            raise ValueError(f'{source}: exceeds instruction ROM')
        # All-zero UNUSED storage deliberately decodes as illegal if executed.
        # No executable instruction is hand-encoded by this script.
        data = data.ljust(4 * pad_words, b'\0')
    words = [f'{int.from_bytes(data[i:i+4], "little"):08x}' for i in range(0, len(data), 4)]
    dest.write_text('\n'.join(words) + '\n')
    # Exact byte round-trip guards against byte/word-endian conversion mistakes.
    back = b''.join(int(w, 16).to_bytes(4, 'little') for w in dest.read_text().split())
    if back != data:
        raise ValueError('hex round-trip mismatch')


def build(name, source, defines=(), vectors=False):
    obj = BUILD / f'{name}.o'
    elf = BUILD / f'{name}.elf'
    binary = BUILD / f'{name}.bin'
    run([TOOLS['as'], '-march=rv32i', '-mabi=ilp32', '-mno-relax',
         *defines, '-o', str(obj), str(source)])
    run([TOOLS['ld'], '-m', 'elf32lriscv', '--no-relax', '-T', 'programs/link.ld',
         '-o', str(elf), str(obj)])
    run([TOOLS['objcopy'], '-O', 'binary', '--only-section=.text', str(elf), str(binary)])
    listing = run([TOOLS['objdump'], '-d', '-M', 'no-aliases,numeric', str(elf)])
    (BUILD / f'{name}.lst').write_text(listing)
    # Check every disassembled 32-bit instruction against the objcopy image.
    blob = binary.read_bytes()
    checked = 0
    for match in re.finditer(r'^\s*([0-9a-f]+):\s+([0-9a-f]{8})\s', listing, re.M):
        offset, encoding = int(match[1], 16), int(match[2], 16)
        if blob[offset:offset+4] != encoding.to_bytes(4, 'little'):
            raise ValueError(f'{name}: objdump/objcopy mismatch at {offset:x}')
        checked += 1
    if not checked:
        raise ValueError(f'{name}: no 32-bit objdump records verified')
    dest = BUILD / 'imm_vectors.hex' if vectors else ROOT / 'programs' / f'{name}.hex'
    bin_to_hex(binary, dest, None if vectors else 1024)
    print(f'BUILT {name}: {len(blob)} bytes; {checked} objdump records verified; {dest.relative_to(ROOT)}')
    return elf


def main():
    missing = [tool for tool in TOOLS.values() if shutil.which(tool) is None]
    if missing:
        raise RuntimeError('Required GNU tools missing: ' + ', '.join(missing) +
                           '. Install RISC-V GNU binutils or set CROSS to its real prefix.')
    for tool in TOOLS.values():
        run([tool, '--version'])
    build('sum', Path('programs/sum.S'))
    build('isa', Path('programs/isa.S'))
    build('imm_vectors', Path('programs/imm_vectors.S'), vectors=True)
    if len((BUILD / 'imm_vectors.bin').read_bytes()) != 13 * 8:
        raise ValueError('Immediate fixture changed size; check assembler relaxation')
    cases = json.loads(Path('programs/fault_cases.json').read_text())
    manifest = []
    for case in cases:
        case_id = case['id']
        elf = build(f'fault_{case_id}', Path('programs/faults.S'),
                    ['--defsym', f'CASE={case_id}'])
        symbols = run([TOOLS['nm'], '-n', str(elf)])
        values = {}
        for line in symbols.splitlines():
            fields = line.split()
            if len(fields) == 3:
                values[fields[2]] = int(fields[0], 16)
        manifest.append({**case, 'pc': values['expected_pc'], 'a0': values['expected_a0'],
                         'hex': f'programs/fault_{case_id}.hex'})
    (BUILD / 'fault_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('PASS GNU assembly, objdump comparison, hex serialization (23 images)')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, ValueError, OSError, KeyError) as exc:
        print(f'FAIL build_programs: {exc}', file=sys.stderr)
        sys.exit(1)
