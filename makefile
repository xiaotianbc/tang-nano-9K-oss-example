BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

TOP_MODULE=uart
# 加入下列行，让make clean等命令可以用cmd执行，避免rm等程序无法运行的问题
SHELL=cmd.exe

all: uart.fs
	
# show activite cmd
ac: 
	D:\FPGA_Learn\oss-cad-suite\environment.bat

# Synthesis
uart.json: uart.v
	yosys -p "read_verilog uart.v; synth_gowin -top ${TOP_MODULE} -json uart.json"

# Place and Route
uart_pnr.json: uart.json
	nextpnr-gowin --json uart.json --freq 27 --write uart_pnr.json --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst --top ${TOP_MODULE}

# Generate Bitstream
uart.fs: uart_pnr.json
	gowin_pack -d ${FAMILY} -o uart.fs uart_pnr.json

# Program Board
load: uart.fs
	openFPGALoader -m -b ${BOARD} uart.fs -f 

uart_test.o: uart.v uart_tb.v
	iverilog -o uart_test.o -s testbench uart.v uart_tb.v

test: uart_test.o
	vvp uart_test.o
	gtkwave wave.vcd

# Cleanup build artifacts
clean:
	del *.vcd uart.fs uart_test.o

.PHONY: load clean test act
.INTERMEDIATE: uart_pnr.json uart.json uart_test.o