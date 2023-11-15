
set TB_NAME tb
set SWITCH_1 SIM

#Define vlib
vlib work

#Compile user files
vlog +define+$SWITCH_1 -f flist_modelsim

#Load the design.
vsim -t ps +notimingchecks -gui -voptargs="+acc" work.$TB_NAME

#Run simulation
run -all
