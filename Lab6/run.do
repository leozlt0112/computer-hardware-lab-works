vlib work

#Compile moudles
vlog part1.sv
vlog part1tb.sv

#Start the simulation
vsim -novopt tb
run -all
exit

