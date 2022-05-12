%builtins output pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.alloc import alloc
from storage import d_storage_read, d_storage_write, DistStorage, get_input_storage, get_input_storage_dict
from starkware.cairo.common.dict import dict_new, dict_write, dict_read, DictAccess, dict_squash
from starkware.cairo.common.serialize import serialize_word

from starkware.cairo.common.default_dict import (
    default_dict_new,
    default_dict_finalize,
)


# For the purposes of this demo, we don't emulate a full Cairo transaction call.
# Instead, we have a very simplified transaction, which modifies a simple piece of 
# state, in order to demonstrate the sharding.
struct Transaction:
    # member input_storage_leaves : felt*
    # member num_input_storage_leaves : felt

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
    member leaves : OutputStorageLeaf*
    member num_output_storage_leaves : felt
end


func main{
    output_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    # IDK if we need this.
    alloc_locals

    # Load the inputs.
    # let (dummy_call : DummyCall*) = alloc()
    local dummy_call : DummyCall*
    %{
        dummy_call = program_input['transaction']['data']

        ids.dummy_call = segments.gen_arg([
            int(dummy_call['key']),
            int(dummy_call['action'])
        ])
    %}

    local d_storage : DistStorage
    let (input_storage_dict) = get_input_storage_dict()
    assert d_storage.dict_start = input_storage_dict
    assert d_storage.dict_end = input_storage_dict

    # Process our sample transaction.
    let (d_storage) = process_transaction(
        d_storage,
        dummy_call,
    )

    # Finalise the output.
    
    # Finalize the state dictionary.
    # Compute the hash of all output leaves.

    let (
        finalized_dict_start, 
        finalized_dict_end
    ) = dict_squash{
        range_check_ptr=range_check_ptr
    }(d_storage.dict_start, d_storage.dict_end)

    # let (
    #     finalized_dict_start, finalized_dict_end
    # ) = default_dict_finalize(d_storage.dict_start, d_storage.dict_end, 0)

    let output = cast(output_ptr, Output*)
    # let output_ptr = output_ptr + Output.SIZE

    copy_to_output(finalized_dict_start, finalized_dict_end, output, 0)
    
    # let (local hash_dict_start : DictAccess*) = dict_new()
    # let (hash_dict_end) = hash_dict_values(finalized_dict_start, finalized_dict_end, hash_dict_start)

    # let (local struct_array : OutputStorageLeaf*) = alloc()
    # compute_merkle(struct_array)

    return ()
end

func copy_to_output{
    output_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
}(
    dict_start : DictAccess*,
    dict_end : DictAccess*,
    output : Output*,
    n : felt
) -> (output : Output*):
    # alloc_locals 
    if dict_start == dict_end:
        return (output=output)
    end

    serialize_word(dict_start.key)
    serialize_word(dict_start.new_value)
    # assert output.leaves[n].key = dict_start.key
    # assert output.leaves[n].value = dict_start.new_value
    # assert output.leaves[n].hash = hash2{hash_ptr=pedersen_ptr}(dict_start.key, dict_start.new_value)

    return copy_to_output(
        dict_start=dict_start + DictAccess.SIZE, dict_end=dict_end, output=output, n=n+1
    )
end

# func hash_dict_values{pedersen_ptr : HashBuiltin*}(
#     dict_start : DictAccess*, dict_end : DictAccess*, hash_dict_start : DictAccess*
# ) -> (hash_dict_end : DictAccess*):
#     if dict_start == dict_end:
#         return (hash_dict_end=hash_dict_start)
#     end

#     # let (prev_hash) = hash_account(account=cast(dict_start.prev_value, Account*))
    
#     let (res) = hash2{hash_ptr=pedersen_ptr}()

#     # let (new_hash) = hash_account(account=cast(dict_start.new_value, Account*))

#     # Add an entry to the output dict.
#     dict_update{dict_ptr=hash_dict_start}(
#         key=dict_start.key, prev_value=prev_hash, new_value=new_hash
#     )
#     return hash_dict_values(
#         dict_start=dict_start + DictAccess.SIZE, dict_end=dict_end, hash_dict_start=hash_dict_start
#     )
# end

# func compute_merkle(
#     finalized_dict_start : DictAccess*, 
#     finalized_dict_end : DictAccess*
# )
#     assert struct_array[0] = MyStruct(first_member=1, second_member=2)
# end

func process_transaction(
    d_storage : DistStorage,
    data : DummyCall*
) -> (d_storage : DistStorage):
    alloc_locals

    let dict_end = d_storage.dict_end

    # Read the current value from distributed storage.
    # let (current_value) = d_storage_read(dict_end, data.key)
    %{ print(ids.data.key) %}
    
    let (current_value : felt) = dict_read{dict_ptr=dict_end}(key=data.key)
    assert current_value = 24

    # Write the new value based on the transaction data.
    # 
    if data.action == 0:
        dict_write{dict_ptr=dict_end}(key=data.key, new_value=(current_value - 1))
    else:
        dict_write{dict_ptr=dict_end}(key=data.key, new_value=(current_value + 1))
    end

    # if data.action == 0:
    #     d_storage_write(dict_end, data.key, current_value - 1)
    # else:
    #     d_storage_write(dict_end, data.key, current_value + 1)
    # end

    local new_d_storage : DistStorage
    assert new_d_storage.dict_start = d_storage.dict_start
    assert new_d_storage.dict_end = dict_end

    return (d_storage=new_d_storage)
end