from storage import d_storage_read, d_storage_write


# For the purposes of this demo, we don't emulate a full Cairo transaction call.
# Instead, we have a very simplified transaction, which modifies a simple piece of 
# state, in order to demonstrate the sharding.
struct Transaction:
    member input_storage_leaves : felt*
    member num_input_storage_leaves : felt

    # Calldata of transcation. 
    # For this demo, full contract execution is mocked.
    member data : DummyCall*
end

struct DummyCall:
    member key : felt

    # 0 for increment, 1 for decrement.
    member action : felt
end

struct OutputStorageLeaf:
    member key : felt
    member value : felt
    member hash : felt
end

struct Output:
    member output_storage_leaves : OutputStorageLeaf*
    member num_output_storage_leaves : felt
end

func main{
    output_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    # IDK if we need this.
    # alloc_locals

    let (tx : Transaction*) = alloc()

    %{
        tx = program_input['transaction']

        ids.tx = segments.gen_arg([
            tx.input_storage_leaves,
            len(tx.input_storage_leaves),
            tx.data,
        ])
    %}

    # Process our sample transaction.
    process_transaction(
        cast(0, felt*),
        tx.data,
    )


    # Write the Merkle roots to the output.
    # let (leaves_before, leaves_after) = compute_merkle_roots(
    #     state=state
    # )
    # assert output.leaves_before = leaves_before
    # assert output.leaves_after = leaves_after

    return ()
end

func process_transaction(
    d_storage_ptr : felt*,
    data : DummyCall*
):
    # Read the current value from distributed storage.
    let (current_value) = d_storage_read(d_storage_ptr, data.key)

    # Write the new value based on the transaction data.
    if data.action == 0:
        d_storage_write(d_storage_ptr, data.key, current_value - 1)
    else:
        d_storage_write(d_storage_ptr, data.key, current_value + 1)
    end

    ret
end