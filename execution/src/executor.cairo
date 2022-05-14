%builtins output pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.alloc import alloc
from storage import DistStorage, get_input_storage, get_input_storage_dict
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
    # Calldata of transcation. 
    # For this demo, full contract execution is mocked.
    member data : DummyCall*
end

struct DummyCall:
    member key : felt

    # 0 for increment, 1 for decrement.
    member action : felt
end

# struct OutputStorageLeaf:
#     member key : felt
#     member value : felt
#     member hash : felt
# end

# struct Output:
#     member leaves : OutputStorageLeaf*
#     member num_output_storage_leaves : felt
# end


func main{
    output_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals

    # Load the inputs.
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
    let (
        finalized_dict_start, 
        finalized_dict_end
    ) = dict_squash{
        range_check_ptr=range_check_ptr
    }(d_storage.dict_start, d_storage.dict_end)
    
    copy_storage_writes_to_output(finalized_dict_start, finalized_dict_end, 0)

    return ()
end

# Copy the dictionary specified by (dict_start, dict_end) to the output memory.
func copy_storage_writes_to_output{
    output_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
}(
    dict_start : DictAccess*,
    dict_end : DictAccess*,
    n : felt
) -> ():
    alloc_locals 

    if dict_start == dict_end:
        return ()
    end

    local prev_hash : felt

    %{
        from starkware.crypto.signature.signature import pedersen_hash

        def find_witness_for_input_storage(key):
            for (input_key, _, input_hash) in input_storage_leaves:
                if int(input_key) == key:
                    return int(input_hash)

        def default_witness(key):
            return pedersen_hash(key, 0, 0)

        def get_storage_leaf_witness(key):
            # Check the input storage leaves.
            witness = find_witness_for_input_storage(key)
            if witness:
                return witness
            else:
                return default_witness(key)

        # Get the previous hash for this storage leaf.
        ids.prev_hash = get_storage_leaf_witness(ids.dict_start.key)
    %}

    # Set res = H(H(key, value), prev_hash).
    let (hash_value) = hash2{hash_ptr=pedersen_ptr}(dict_start.key, dict_start.new_value)
    let (hash_value) = hash2{hash_ptr=pedersen_ptr}(hash_value, prev_hash)

    serialize_word(dict_start.key)
    serialize_word(dict_start.new_value)
    serialize_word(hash_value)

    return copy_storage_writes_to_output(
        dict_start=dict_start + DictAccess.SIZE, dict_end=dict_end, n=n+1
    )
end

func process_transaction(
    d_storage : DistStorage,
    data : DummyCall*
) -> (d_storage : DistStorage):
    alloc_locals

    let storage_end = d_storage.dict_end

    # Read the current value from distributed storage.
    let (current_value : felt) = dict_read{dict_ptr=storage_end}(key=data.key)

    # Write the new value based on the transaction data.
    # 
    if data.action == 0:
        dict_write{dict_ptr=storage_end}(key=data.key, new_value=(current_value - 1))
    else:
        dict_write{dict_ptr=storage_end}(key=data.key, new_value=(current_value + 1))
    end

    local new_d_storage : DistStorage
    assert new_d_storage.dict_start = d_storage.dict_start
    assert new_d_storage.dict_end = storage_end

    return (d_storage=new_d_storage)
end