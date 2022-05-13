set -ex
cairo-compile executor.cairo --output out/executor_compiled.json
cairo-run --program=out/executor_compiled.json --print_output --layout=small --program_input=input.json --memory_file out/memory.bin --trace_file out/trace.bin --program_output_file out/output.json --debug_info_file out/debug.json --print_segments