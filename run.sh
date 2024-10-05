

error_msg=$(/home/alexhelmersson/Documents/programming/verilator/bin/verilator -f configs/verilator/verilator.f 2>&1 > /dev/null)

printf "error_msg: %s\n" "${error_msg}"

if [ -z "${error_msg}" ]; then

	./obj_dir/Vtb

	gtkwave waves.vcd configs/gtkwave/gtkwave_signals.gtkw 

fi
