######### Ex 00
## A contract from which other contracts can import functions

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check
)
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)

from contracts.token.ERC20.IERC20 import IERC20
from contracts.token.ERC20.ITDERC20 import ITDERC20
from contracts.utils.Iplayers_registry import Iplayers_registry
from contracts.lib.SKNTD import SKNTD_assert_uint256_difference
from contracts.IERC20Solution import IERC20Solution

#
# Declaring storage vars
# Storage vars are by default not visible through the ABI. They are similar to "private" variables in Solidity
#

@storage_var
func tderc20_address_storage() -> (tderc20_address_storage : felt):
end

@storage_var
func players_registry_storage() -> (tderc20_address_storage : felt):
end

@storage_var
func workshop_id_storage() -> (workshop_id_storage : felt):
end

@storage_var
func Teacher_accounts(account : felt) -> (balance : felt):
end

#
# Declaring getters
# Public variables should be declared explicitely with a getter
#

@view
func tderc20_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (_tderc20_address : felt):
    let (_tderc20_address) = tderc20_address_storage.read()
    return (_tderc20_address)
end

@view
func players_registry{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (_players_registry : felt):
    let (_players_registry) = players_registry_storage.read()
    return (_players_registry)
end

@view
func has_validated_exercise{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(account : felt, exercise_id : felt) -> (has_validated_exercise : felt):
    # reading player registry
    let (_players_registry) = players_registry_storage.read()
    let (_workshop_id) = workshop_id_storage.read()
    # Checking if the user already validated this exercise
    let (has_current_user_validated_exercise) = Iplayers_registry.has_validated_exercise(contract_address=_players_registry, account=account, workshop=_workshop_id, exercise = exercise_id)
    return (has_current_user_validated_exercise)
end

#
# Internal constructor
# This function is used to initialize the contract. It can be called from the constructor
#

func ex_initializer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _tderc20_address : felt,
        _players_registry : felt,
        _workshop_id : felt
    ):
    tderc20_address_storage.write(_tderc20_address)
    players_registry_storage.write(_players_registry)
    workshop_id_storage.write(_workshop_id)
    return ()
end

#
# Internal functions
# These functions can not be called directly by a transaction
# Similar to internal functions in Solidity
#

func distribute_points{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(to : felt, amount : felt):
    # Converting felt to uint256. We assume it's a small number
    # We also add the required number of decimals
    let points_to_credit : Uint256 = Uint256(amount*1000000000000000000, 0)
    # Retrieving contract address from storage
    let (contract_address) = tderc20_address_storage.read()
    # Calling the ERC20 contract to distribute points
    ITDERC20.distribute_points(contract_address=contract_address, to = to, amount = points_to_credit)
    return()
end

func validate_exercise{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(account : felt, exercise_id):
    # reading player registry
    let (_players_registry) = players_registry_storage.read()
    let (_workshop_id) = workshop_id_storage.read()
    # Checking if the user already validated this exercise
    let (has_current_user_validated_exercise) = Iplayers_registry.has_validated_exercise(contract_address=_players_registry, account=account, workshop=_workshop_id, exercise = exercise_id)
    assert (has_current_user_validated_exercise) = 0

    # Marking the exercise as completed
    Iplayers_registry.validate_exercise(contract_address=_players_registry, account=account, workshop=_workshop_id, exercise = exercise_id)

    return()
end

func validate_and_distribute_points_once{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender_address : felt,
        exercise : felt,
        points : felt):

    # Checking if player has validated this exercise before
    let(has_validated) = has_validated_exercise(sender_address, exercise)
    # This is necessary because of revoked references. Don't be scared, they won't stay around for too long...

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if has_validated == 0:
        # player has validated
        validate_exercise(sender_address, exercise)
        # Sending Setup, contract & deployment points
        distribute_points(sender_address, points)
    end
    return()
end


@external
func test_get_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
        }(tested_contract : felt) -> (has_received_tokens : felt, amount_received : Uint256):
    # This function will 
    # * get initial evaluator balance on the given contract, 
    # * call that contract's `get_tokens`
    # * get the evaluator's final balance
    # and return two values:
    # * Whether the evaluator's balance increased or not
    # * The balance difference (amount)
    # It will also make sure that the two values are consistent (asserts will fail otherwise)
    alloc_locals
    let (evaluator_address) = get_contract_address()

    let (initial_balance) = IERC20.balanceOf(contract_address=tested_contract, account=evaluator_address)
    let (amount_received) = IERC20Solution.get_tokens(contract_address=tested_contract)

    # Checking returned value
    let zero_as_uint256 : Uint256 = Uint256(0, 0)
    let (has_received_tokens) = uint256_lt(zero_as_uint256, amount_received)

    # Checking that current balance is initial_balance + amount_received (even if 0)
    let (final_balance) = IERC20.balanceOf(contract_address=tested_contract, account=evaluator_address)
    SKNTD_assert_uint256_difference(final_balance, initial_balance, amount_received)

    return (has_received_tokens, amount_received)
end

func only_teacher{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (caller) = get_caller_address()
    let (permission) = Teacher_accounts.read(account=caller)
    assert permission = 1
    return ()
end

@external
func set_teacher{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account : felt, permission : felt):
    only_teacher()
    Teacher_accounts.write(account, permission)

    return ()
end

@view
func is_teacher{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account : felt) -> (permission : felt):
    let (permission : felt) = Teacher_accounts.read(account)
    return (permission)
end

