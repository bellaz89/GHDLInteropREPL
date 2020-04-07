ifdef GHDL
	GHDL=$(GHDL)
else
	GHDL=ghdl
endif

CC=g++
CFLAGS= -std=c++11 -pedantic -Wall -Wextra -g
LDFLAGS=-lrt -lpthread
OUTPUT=./test.vcd
OUTPUT_TYPE=vcd

all:
	$(GHDL) -a $(COMPONENT_SOURCE)
	$(GHDL) --bind $(COMPONENT_NAME)
	$(CC) -c  ghdlIface.cpp -o ghdlIface.o $(CFLAGS)
	$(CC) -c  main.cpp -o main.o $(CFLAGS)
	$(CC)  main.o ghdlIface.o  -Wl,`ghdl --list-link $(COMPONENT_NAME)` $(CFLAGS) $(LDFLAGS) -o simulation
	./simulation

vpi_plugin:
	$(GHDL) --vpi-compile $(CC) -DVPI_ENTRY_POINT_PTR=$(ENTRY_POINT_PTR) -c -o vpi_plugin.o vpi_plugin.c $(CFLAGS)
	$(GHDL) --vpi-link $(CC) -o vpi_plugin.vpi vpi_plugin.o

ghdl-mcode:
	ghdl-mcode -a $(COMPONENT_SOURCE)
	ghdl-mcode -e $(COMPONENT_NAME)
	ghdl-mcode --vpi-compile $(CC) -c VpiPlugin.cpp $(CFLAGS) -o VpiPlugin.o
	ghdl-mcode --vpi-link $(CC)  VpiPlugin.o $(LDFLAGS) $(CFLAGS) -o VpiPlugin.vpi
	$(CC) -c  main.cpp -DRUN_SIMULATOR_COMMAND='"make run_ghdl-mcode"' -o main.o $(CFLAGS)
	$(CC) -c  SharedMemIface.cpp -o SharedMemIface.o $(CFLAGS)
	$(CC) main.o SharedMemIface.o -o main $(CFLAGS) $(LDFLAGS)
	./main

run_ghdl-mcode:
	ghdl-mcode -r $(COMPONENT_NAME) --vpi=./VpiPlugin.vpi --$(OUTPUT_TYPE)=$(OUTPUT) &> /dev/null &

ghdl-gcc:
	ghdl-gcc -a $(COMPONENT_SOURCE)
	ghdl-gcc -e $(COMPONENT_NAME)
	ghdl-gcc --vpi-compile $(CC) -c VpiPlugin.cpp $(CFLAGS) -o VpiPlugin.o 
	ghdl-gcc --vpi-link $(CC) VpiPlugin.o $(LDFLAGS) $(CFLAGS) -o VpiPlugin.vpi
	$(CC) -c  main.cpp -DRUN_SIMULATOR_COMMAND='"make run_ghdl-gcc"' -o main.o $(CFLAGS)
	$(CC) -c  SharedMemIface.cpp -o SharedMemIface.o $(CFLAGS)
	$(CC) main.o SharedMemIface.o -o main $(CFLAGS) $(LDFLAGS)
	./main

run_ghdl-gcc:
	ghdl-gcc -r $(COMPONENT_NAME) --vpi=./VpiPlugin.vpi --$(OUTPUT_TYPE)=$(OUTPUT) &> /dev/null &

ghdl-llvm:
	ghdl-llvm -a $(COMPONENT_SOURCE)
	ghdl-llvm -e $(COMPONENT_NAME)
	ghdl-llvm --vpi-compile $(CC) -c VpiPlugin.cpp $(CFLAGS) -o VpiPlugin.o 
	ghdl-llvm --vpi-link $(CC) VpiPlugin.o $(LDFLAGS) $(CFLAGS) -o VpiPlugin.vpi
	$(CC) -c  main.cpp -DRUN_SIMULATOR_COMMAND='"make run_ghdl-llvm"' -o main.o $(CFLAGS)
	$(CC) -c  SharedMemIface.cpp -o SharedMemIface.o $(CFLAGS)
	$(CC) main.o SharedMemIface.o -o main $(CFLAGS) $(LDFLAGS)
	./main

run_ghdl-llvm:
	ghdl-llvm -r $(COMPONENT_NAME) --vpi=./VpiPlugin.vpi --$(OUTPUT_TYPE)=$(OUTPUT) &> /dev/null &

iverilog:
	$(CC) -c VpiPlugin.cpp $(CFLAGS) $(shell iverilog-vpi --cflags) -o VpiPlugin.o
	$(CC) VpiPlugin.o $(CFLAGS) $(shell iverilog-vpi --cflags) $(shell iverilog-vpi --lflags) $(shell iverilog-vpi --ldlibs) $(LDFLAGS) -shared -o VpiPlugin.vpi
	iverilog  $(COMPONENT_SOURCE) -s $(COMPONENT_NAME) -o iverilog_compiled.vvp
	$(CC) -c  main.cpp -DRUN_SIMULATOR_COMMAND='"make run_iverilog"' -o main.o $(CFLAGS)
	$(CC) -c  SharedMemIface.cpp -o SharedMemIface.o $(CFLAGS)
	$(CC) main.o SharedMemIface.o -o main $(CFLAGS) $(LDFLAGS)
	./main

run_iverilog:
	vvp -M. -mVpiPlugin iverilog_compiled.vvp -$(OUTPUT_TYPE) &> /dev/null &




clean:
	rm -f *.vpi
	rm -f *.o
	rm -f *.out
	rm -f *.so
	rm -f simulation
	rm -f *.lst
	rm -f *.cf
	rm -f *.vcd


.PHONY: ghdl-mcode ghdl-gcc ghdl-llvm iverilog run_ghdl-mcode run_ghdl-gcc run_ghdl-llvm iverilog 