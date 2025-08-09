SHELL := /bin/sh
.ONESHELL:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

BIN = ./bin/

ZCC_FLAGS := --math32 -SO3 --max-allocs-per-node200000  -I./include --vc -Cs --Werror  -DVDP_SUPER_HDMI
USER_ID := $(shell id -u ${USER})
GROUP_ID := $(shell id -g ${USER})
Z88DK_DOCKER := docker run --rm -w /host/$${PWD} -v /:/host/ -u $(USER_ID):$(GROUP_ID) -t z88dk/z88dk
Z88DK_DOCKER_MAKE := $(Z88DK_DOCKER)
ZCC := $(Z88DK_DOCKER_MAKE) zcc +cpm -compiler=sdcc $(ZCC_FLAGS)

define compile
	@set -e
	@mkdir -p $(dir $@)
	echo "Compiling $(filter-out %.inc,$(filter-out %.h,$(filter-out %.lib,$^))) to $(notdir $@)"
	$(ZCC) $(foreach lib,$(filter %.lib,$^),-l$(lib)) $(filter-out %.inc,$(filter-out %.h,$(filter-out %.lib,$^))) -o $@ -create-app
endef

define buildlib
	@mkdir -p $(dir $@)
	echo "Packaging $(notdir $@) from $(notdir $<)"
	$(Z88DK_DOCKER_MAKE) z88dk-z80asm -x$@ $^
endef

all:  $(BIN)SUPHDMI.COM $(BIN)SHWS2812.COM

V99X8_C_FILES=$(wildcard ./library/v99x8/*.c)
V99X8_C_ASM_FILES= $(patsubst %.c,%.c.asm,$(V99X8_C_FILES))
V99X8_ASM_FILES=$(wildcard ./library/v99x8/*.asm)
Z80_FILES=$(wildcard ./library/z80/*.asm)
CPM_FILES=$(wildcard ./library/cpm/*.asm)
HBIOS_FILES=$(wildcard ./library/hbios/*.asm)
WFK_C_FILES=$(wildcard ./library/waitforkey/*.c)
WFK_C_ASM_FILES= $(patsubst %.c,%.c.asm,$(WFK_C_FILES))

$(BIN):
	@mkdir -p $(BIN)

library/v99x8/%.c.asm: library/v99x8/%.c
	@echo "Compiling $< to $@"
	@$(ZCC) -I./include --vc -Cs --Werror -S $< -o $@

library/waitforkey/%.c.asm: library/waitforkey/%.c
	@echo "Compiling $< to $@"
	@$(ZCC) -I./include --vc -Cs --Werror -S $< -o $@

$(BIN)v99x8.lib: $(V99X8_C_ASM_FILES) $(V99X8_ASM_FILES)
	$(buildlib)

$(BIN)z80.lib: $(Z80_FILES)
	$(buildlib)

$(BIN)cpm.lib: $(CPM_FILES)
	$(buildlib)

$(BIN)waitforkey.lib: $(WFK_C_ASM_FILES)
	$(buildlib)

$(BIN)hbios.lib: $(HBIOS_FILES)
	$(buildlib)

$(BIN)SUPHDMI.COM: suphdmi/suphdmi.c suphdmi/sysfont.asm $(BIN)waitforkey.lib $(BIN)v99x8.lib $(BIN)z80.lib $(BIN)cpm.lib | $(BIN)
	$(compile)

$(BIN)SHWS2812.COM: shws2812/shws2812.c $(BIN)waitforkey.lib $(BIN)v99x8.lib $(BIN)z80.lib $(BIN)cpm.lib $(BIN)hbios.lib | $(BIN)
	$(compile)
