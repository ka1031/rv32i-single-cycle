# Verification status

Verified on **2026-10-23**. GNU program assembly, all directed HDL regressions, and Verilator lint completed successfully. Earlier reports of missing tools from 2026-10-04 are superseded by this run.

## Reproduce the checks

Run from the project root with Python 3, GNU Make, RISC-V GNU binutils, Icarus Verilog, and Verilator installed:

```bash
python3 scripts/check_sources.py
make all CROSS=riscv64-unknown-elf-
```

Both commands exited with status 0. The Makefile defaults to `riscv32-unknown-elf-`; this run used the installed `riscv64-unknown-elf-` tools to produce RV32I/ILP32 executables.

Tool versions used:

- GNU RISC-V binutils 2.42.
- Icarus Verilog 12.0 (stable).
- Verilator 5.020.

## Results

- **Source checks passed:** Python syntax, the 11-file RTL list, absence of lint suppression pragmas, the 20-case fault manifest, and absence of hand-encoded instructions in assembly sources. These checks do not replace HDL compilation or simulation.
- **GNU assembly passed:** all 23 images (sum, ISA, immediate vectors, and 20 fault cases) were assembled and linked. The build verified objdump records against objcopy bytes and checked hex serialization.
- **Six unit testbenches passed:** ALU (20 checks), register file (69 checks), immediate generator (13 GNU instruction vectors), branch unit (20 checks), data memory (28 checks), and fault unit (enabled and bypassed).
- **Both normal core tests passed:** the sum program completed in 41 cycles and the ISA program in 320 cycles. The sum test checked the result of 55, its stored byte order, and register load-back.
- **All 20 fault scenarios passed:** cases 0 through 19 checked the expected fault cause and PC, with checks for suppressed side effects and sticky fault behavior.
- **Verilator lint passed without warnings:** `--lint-only -Wall` on `riscv_core` and `--lint-only --timing -Wall` on all eight testbenches. No warning suppression was used.

The observed completion markers were:

```text
PASS GNU assembly, objdump comparison, hex serialization (23 images)
PASS regression mode=all
PASS Verilator -Wall (RTL and all testbenches)
```

Icarus emitted compilation diagnostics, including its constant-select limitation for `always_*` sensitivity handling. Compilation and simulation still exited successfully. The warning-free claim applies specifically to the Verilator lint gate.

## Generated outputs

`make all` regenerates program images in `programs/*.hex`, object files, ELF files, binaries, disassembly listings, the immediate-vector image, fault metadata, simulator executables, and waveforms in `build/`. Regression and lint output are written to `logs/all.log` and `logs/lint.log`.

These generated files are ignored by Git. A fresh checkout must run the build before using direct simulator commands. The older `logs/execution.txt` and `logs/execution.json`, if present locally, describe historical attempts and are not the current verification record.

## Verification limits

The suite is directed, not exhaustive. Technology synthesis, resource utilization, static timing analysis, formal verification, and a full architectural compliance suite have not been run or claimed. Passing lint does not establish synthesis or timing closure.

Waveforms were generated, but interactive GTKWave inspection was not performed as part of this verification. To inspect the sum waveform after running the tests:

```bash
make wave
```
