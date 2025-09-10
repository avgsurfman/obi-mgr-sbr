# Check whether verilator is installed
# https://stackoverflow.com/questions/592620/how-can-i-check-if-a-program-exists-from-a-bash-script

if ! command -v verilator 
then
    echo "Verilator is not installed. Use any other sim that is NOT iverilog due to \n
    the lack of Array assignment patterns support (as of 2025/9/9)."
    exit 1
else
# verilator --main main.sv -Iip/obi/include -Iip/common_cells/include --top-module add_compare
verilator --binary main_tb.sv -Iip/obi/include -Iip/common_cells/include --trace
./obj_dir/Vmain_tb
fi
