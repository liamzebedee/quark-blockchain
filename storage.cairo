

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.alloc import alloc

struct InputStorageLeaf:
    member key : felt
    member value : felt

    # Leaf identity = H(commitment, key, value)
    # Prev hash is that of the leaf before.
    member prev_hash : felt
    # hash = hash(prev_hash, concat(key, value))
end

struct DistributedStorage:
    member account_dict_start : DictAccess*
end

# let account_dict_end = state.account_dict_end

# # Retrieve the pointer to the current state of the account.
# let (local old_account : Account*) = dict_read{
#     dict_ptr=account_dict_end
# }(key=account_id)

# dict_write{dict_ptr=account_dict_end}(
#     key=account_id, new_value=cast(&new_account, felt)
# )
# local new_state : AmmState
# assert new_state.account_dict_start = (
#     state.account_dict_start)
# assert new_state.account_dict_end = account_dict_end


func d_storage_write(
    d_storage_ptr : felt*,
    key : felt,
    value : felt
):
    ret
end

func d_storage_read(
    d_storage_ptr : felt*,
    key : felt
) -> (value : felt):
    # Get the value from the storage leaves.
    ret
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
