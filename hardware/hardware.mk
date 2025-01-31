ifeq ($(filter VEXRISCV, $(HW_MODULES)),)

include $(VEXRISCV_DIR)/config.mk

HW_MODULES+=VEXRISCV

#PATHS
VEXRISCV_SRC_DIR=$(VEXRISCV_DIR)/hardware/src

VSRC+=$(VEXRISCV_SRC_DIR)/VexRiscv.v $(VEXRISCV_SRC_DIR)/iob_VexRiscv.v

#use hard multiplier and divider instructions
DEFINE+=$(defmacro)USE_MUL_DIV=$(USE_MUL_DIV)

#use compressed instructions
DEFINE+=$(defmacro)USE_COMPRESSED=$(USE_COMPRESSED)

endif
