TARGET = demo
ALT_DEVICE_FAMILY ?= soc_cv_av
SOCEDS_ROOT = c:/intelFPGA_lite/17.0/embedded
HWLIBS_ROOT = $(SOCEDS_ROOT)/ip/altera/hps/altera_hps/hwlib
CROSS_COMPILE = arm-linux-gnueabihf-
CFLAGS = -g -Wall  \
	-D$(ALT_DEVICE_FAMILY) \
	-I../conversion \
	-I$(HWLIBS_ROOT)/include/$(ALT_DEVICE_FAMILY) \
	-I$(HWLIBS_ROOT)/include/
LDFLAGS =  -g -Wall 
CC = $(CROSS_COMPILE)gcc
ARCH= arm
OBJDUMP=$(CROSS_COMPILE)objdump

build: $(TARGET)

$(TARGET): main.o
	$(CC) $(LDFLAGS)   $^ -o $@
	$(OBJDUMP) -D $@ >$(TARGET).lst

%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm -f $(TARGET) *.a *.o *~ $(TARGET).lst
