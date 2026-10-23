# Invoke from this directory. GNU binutils must support RV32I / ELF32 RISC-V.
PYTHON ?= python3
CROSS ?= riscv32-unknown-elf-
export CROSS
.PHONY: all programs unit core test lint wave clean
all: test lint
programs:
	$(PYTHON) scripts/build_programs.py
unit: programs
	$(PYTHON) scripts/run_tests.py unit
core: programs
	$(PYTHON) scripts/run_tests.py core
test: programs
	$(PYTHON) scripts/run_tests.py all
lint:
	$(PYTHON) scripts/run_tests.py lint
wave:
	gtkwave build/sum.vcd
clean:
	$(PYTHON) -c "from pathlib import Path; import shutil; [shutil.rmtree(p, ignore_errors=True) for p in ('build','logs')]; [p.unlink() for p in Path('programs').glob('*.hex')]"
