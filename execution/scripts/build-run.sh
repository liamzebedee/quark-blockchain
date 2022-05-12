set -ex
cairo-compile example.cairo --output example_compiled.json
cairo-run --program=example_compiled.json --print_output --layout=small --program_input=input.json