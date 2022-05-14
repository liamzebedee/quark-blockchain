set -ex

cd src/
cairo-compile ../src/executor.cairo --output ../out/executor_compiled.json

cd ..
cairo-run \
    --program=out/executor_compiled.json \
    --print_output \
    --print_segments \
    --layout=small --tracer \
    --program_input=input.json \
    --memory_file out/memory.bin \
    --trace_file out/trace.bin \
    --program_output_file out/output.json \
    --debug_info_file out/debug.json 