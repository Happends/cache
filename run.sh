

msg=$(/home/alexhelmersson/Documents/programming/verilator/bin/verilator -f configs/verilator/verilator.f 2>&1)

printf "msg: %s\n" "${msg}"

error_msg=$(echo "${msg}" | grep "%Error")

echo "error: ${error_msg}"

if [ -z "${error_msg}" ]; then

	./obj_dir/Vtb

	gtkwave waves.vcd configs/gtkwave/gtkwave_signals.gtkw 

fi
