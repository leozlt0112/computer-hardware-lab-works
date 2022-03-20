vlib work

#Compile moudles
vlog cpu.sv
vlog tb.sv

#Start the simulation
vsim -novopt tb
run -all 
exit 