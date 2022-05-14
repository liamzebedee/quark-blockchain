executor
========

The executor is a simple proof-of-concept of a more generalized blockchain transaction state machine. 

## Usage.

You will need my forked version (`https://github.com/liamzebedee/cairo-lang`) of the Cairo toolchain, which supports writing the output memory to a file.

```
# Runs the Cairo program with the input in input.json.
./scripts/build-run.sh

# See the output witness.
cat out/output.json
```


### `executor.cairo`

The executor provides a framework for persistent storage for a Cairo program. 

#### Input

The transaction specifies its calldata in `data` and the storage it reads from in `input_storage_leaves`. `input_storage_leaves` is a list of `(key, value, hash)` pairs.

```json
{
    "transaction": {
        "input_storage_leaves": [
            ["420", "1", "123"],
            ["999", "23", "3543433"]
        ],
        "data": {
            "key": "420",
            "action": "1"
        }
    }
}
```

#### Output

The transaction's output is written to `out/output.json`. It contains a binary representation of the output storage leaves - `(key, value, hash)` pairs.

```json
{
    "output_memory": [
        420,
        1,
        2124455138055794670287887347254074419102033860719943774850916465766417634986
    ]
}
```


