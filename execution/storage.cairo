

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.default_dict import (
    default_dict_new,
    default_dict_finalize,
)
from starkware.cairo.common.dict import dict_new, dict_write, dict_read
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.registers import get_fp_and_pc



struct InputStorageLeaf:
    member key : felt
    member value : felt

    # Leaf identity = H(commitment, key, value)
    # Prev hash is that of the leaf before.
    member prev_hash : felt
    # hash = hash(prev_hash, concat(key, value))
end

struct DistStorage:
    member dict_start : DictAccess*
    # Pointer to end of the storage dictionary accesses.
    member dict_end : DictAccess*
end

# Gets the distributed storage, initialized with the input storage leaves
# specified in the hint `transcation.input_storage_leaves`.
func get_input_storage_dict() -> (dict : DictAccess*):
    alloc_locals
    
    %{
        input_storage_leaves = program_input['transaction']['input_storage_leaves']
        
        initial_dict = {
            # int(key): segments.gen_arg([
            #     int(value), 
            #     int(prev_hash)
            # ])
            int(key): int(value)
            for (key, value, prev_hash) in input_storage_leaves
        }
    %}

    # Initialize the dictionary.
    # let (dict) = dict_new()
    let (dict) = default_dict_new(default_value=0)
    
    return (dict=dict)
end

func get_input_storage() -> (d_storage : DistStorage):
    alloc_locals

    local d_storage : DistStorage
    
    let (input_storage_dict) = get_input_storage_dict()
    assert d_storage.dict_start = input_storage_dict
    assert d_storage.dict_end = input_storage_dict

    # LEARN: Using the value of fp directly, requires defining a variable named __fp__.
    # LEARN: let (__fp__, _) = get_fp_and_pc()
    return (d_storage=d_storage)
end

func d_storage_read(
    dict_end_ptr : DictAccess*,
    key : felt
) -> (value : felt):
    # Get the value from the storage leaves.
    let (value : felt) = dict_read{dict_ptr=dict_end_ptr}(key=key)
    return (value=value)
end

func d_storage_write(
    dict_end_ptr : DictAccess*,
    key : felt,
    value : felt
):
    # Implicit argument binding must be an identifier.
    dict_write{dict_ptr=dict_end_ptr}(key=key, new_value=value)
    return ()
end









# Adds amount to the account's balance for the given token.
# amount may be positive or negative.
# Assert before setting that the balance does not exceed the upper bound.
# func modify_account_balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     account_id : felt, token_type : felt, amount : felt
# ):
#     let (current_balance) = account_balance.read(account_id, token_type)
#     tempvar new_balance = current_balance + amount
#     assert_nn_le(new_balance, BALANCE_UPPER_BOUND - 1)
#     account_balance.write(account_id=account_id, token_type=token_type, value=new_balance)
#     return ()
# end

# const STORAGE_READ_SELECTOR = 'StorageRead'

# Describes the StorageRead system call format.
# struct StorageReadRequest:
#     # The system call selector (= STORAGE_READ_SELECTOR).
#     member selector : felt
#     member address : felt
# end

# struct StorageReadResponse:
#     member value : felt
# end

# struct StorageRead:
#     member request : StorageReadRequest
#     member response : StorageReadResponse
# end

# func storage_read{syscall_ptr : felt*}(address : felt) -> (value : felt):
#     let syscall = [cast(syscall_ptr, StorageRead*)]
#     assert syscall.request = StorageReadRequest(selector=STORAGE_READ_SELECTOR, address=address)
#     %{ syscall_handler.storage_read(segments=segments, syscall_ptr=ids.syscall_ptr) %}
#     let response = syscall.response
#     let syscall_ptr = syscall_ptr + StorageRead.SIZE
#     return (value=response.value)
# end

# const STORAGE_WRITE_SELECTOR = 'StorageWrite'

# # Describes the StorageWrite system call format.
# struct StorageWrite:
#     member selector : felt
#     member address : felt
#     member value : felt
# end

# func storage_write{syscall_ptr : felt*}(address : felt, value : felt):
#     assert [cast(syscall_ptr, StorageWrite*)] = StorageWrite(
#         selector=STORAGE_WRITE_SELECTOR, address=address, value=value)
#     %{ syscall_handler.storage_write(segments=segments, syscall_ptr=ids.syscall_ptr) %}
#     let syscall_ptr = syscall_ptr + StorageWrite.SIZE
#     return ()
# end
