set -ex
cairo-compile executor.cairo --output executor_compiled.json
cairo-run --program=executor_compiled.json --print_output --layout=small --program_input=input.json