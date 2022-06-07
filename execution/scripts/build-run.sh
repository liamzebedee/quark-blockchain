set -ex

cd src/
cairo-compile ../src/executor.cairo --output ../out/compiled.json #--proof_mode

cd ..

cairo-run \
    --program=./out/compiled.json \
    --print_output \
    --print_segments \
    --print_info \
    --layout all \
    --program_input ./input.json \
    --memory_file ./out/memory.bin \
    --trace_file ./out/trace.bin \
    --program_output_file ./out/output.json \
    # --proof_mode \
    # --air_public_input ./out/air_public_input.json \
    # --air_private_input ./out/air_private_input.json
    # --tracer \
    # --cairo_pie_output out/pie.zip \
    # --debug_info_file out/debug.json \