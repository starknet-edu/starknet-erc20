######### ERC-20 evaluator
# Soundtrack https://www.youtube.com/watch?v=iuWa5wh8lG0

%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_lt, assert_not_zero

from contracts.utils.ex00_base import (
    tderc20_address,
    distribute_points,
    ex_initializer,
    has_validated_exercise,
    validate_exercise,
    only_teacher,
    Teacher_accounts
)
from contracts.IExerciseSolution import IExerciseSolution
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_mul, uint256_le, uint256_lt, uint256_check, uint256_eq
)
from contracts.token.ERC20.ITDERC20 import ITDERC20
from contracts.token.ERC20.IERC20 import IERC20

#
# Declaring storage vars
# Storage vars are by default not visible through the ABI. They are similar to "private" variables in Solidity
#

@storage_var
func max_rank_storage() -> (max_rank: felt):
end

@storage_var
func next_rank_storage() -> (next_rank: felt):
end

@storage_var
func random_attributes_storage(column: felt, rank: felt) -> (value: felt):
end

@storage_var
func assigned_rank_storage(player_address: felt) -> (rank: felt):
end

@storage_var
func has_been_paired(contract_address: felt) -> (has_been_paired: felt):
end

@storage_var
func player_exercise_solution_storage(player_address: felt) -> (contract_address: felt):
end

@storage_var
func dummy_token_address_storage() -> (dummy_token_address_storage: felt):
end

@storage_var
func first_listing_storage(submitted_exercise_address: felt) -> (denied: felt):
end

@storage_var
func first_listing_multi_storage(submitted_exercise_address: felt) -> (denied: felt):
end

@storage_var
func second_listing_multi_storage(submitted_exercise_address: felt) -> (amount: Uint256):
end

#
# Declaring getters
# Public variables should be declared explicitly with a getter
#

@view
func next_rank{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (next_rank: felt):
    let (next_rank) = next_rank_storage.read()
    return (next_rank)
end

@view
func player_exercise_solution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player_address: felt) -> (contract_address: felt):
    let (contract_address) = player_exercise_solution_storage.read(player_address)
    return (contract_address)
end

@view
func assigned_rank{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player_address: felt) -> (rank: felt):
    let (rank) = assigned_rank_storage.read(player_address)
    return (rank)
end

@view
func read_ticker{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player_address: felt) -> (ticker: felt):
    let (rank) = assigned_rank(player_address)
    let (ticker) = random_attributes_storage.read(0, rank)
    return (ticker)
end

@view
func read_supply{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player_address: felt) -> (supply: Uint256):
    let (rank) = assigned_rank(player_address)
    let (supply_felt) = random_attributes_storage.read(1, rank)
    let supply: Uint256 = Uint256(supply_felt, 0)
    return (supply)
end

######### Constructor
# This function is called when the contract is deployed
#
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _players_registry: felt,
        _tderc20_address : felt,
        _dummy_token_address: felt, 
        _workshop_id: felt,
        _first_teacher: felt):
    ex_initializer(_tderc20_address, _players_registry, _workshop_id)
    dummy_token_address_storage.write(_dummy_token_address)
    Teacher_accounts.write(_first_teacher, 1)
    # Hard coded value for now
    max_rank_storage.write(100)
    return ()
end


######### External functions
# These functions are callable by other contracts
#

@external
func ex1a_assign_rank{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # Allocating locals. Make your code easier to write and read by avoiding some revoked references
    alloc_locals

    # Reading caller address
    let (sender_address) = get_caller_address()

    assign_rank_to_player(sender_address)

    # Checking if player has validated this exercise before
    let (has_validated) = has_validated_exercise(sender_address, 1)

    # This is necessary because of revoked references. Don't be scared, they won't stay around for too long...
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if has_validated == 0:
        # player has validated
        validate_exercise(sender_address, 1)
        # Sending points
        distribute_points(sender_address, 1)
    end
    return()
end


@external
func ex1b_test_erc20{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading caller address
    let (sender_address) = get_caller_address()
    
    # Retrieve expected characteristics
    let (expected_supply) = read_supply(sender_address)
    let (expected_symbol) = read_ticker(sender_address)

    # Retrieve exercise address
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address)

    # Reading supply of submission address
    let (submission_supply) = IERC20.totalSupply(contract_address = submitted_exercise_address)
    # Checking supply is correct
    let (is_equal) = uint256_eq(submission_supply, expected_supply)
    assert  is_equal = 1

    # Reading symbol of submission address
    let (submission_symbol) = IERC20.symbol(contract_address = submitted_exercise_address)
    # Checking symbol is correct
    assert submission_symbol = expected_symbol
    
    # Checking some ERC20 functions were created
    let (contract_address) = get_contract_address()

    let (balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = contract_address)
    let (initial_allowance) = IERC20.allowance(contract_address=submitted_exercise_address, owner=contract_address, spender=sender_address)

    # 10 tokens
    let ten_tokens_as_uint256: Uint256 = Uint256(10 * 1000000000000000000, 0)
    IERC20.approve(contract_address = submitted_exercise_address, spender = sender_address, amount = ten_tokens_as_uint256)

    let (final_allowance) = IERC20.allowance(contract_address = submitted_exercise_address, owner = contract_address, spender = sender_address)
    let (difference) = uint256_sub(final_allowance, initial_allowance)
    assert difference = ten_tokens_as_uint256

    # Checking if player has validated this exercise before
    let (has_validated) = has_validated_exercise(sender_address, 2)

    # This is necessary because of revoked references. Don't be scared, they won't stay around for too long...
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if has_validated == 0:
        # player has validated
        validate_exercise(sender_address, 2)
        # Sending points
        distribute_points(sender_address, 2)
    end
    return()
end


@external
func ex3_test_get_token{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (sender_address) = get_caller_address()
    let (evaluator_address) = get_contract_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address)

    let (initial_balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = evaluator_address)
    let (amount_received) = IExerciseSolution.get_token(contract_address = submitted_exercise_address)
    # Checking returned value
    let zero_as_uint256: Uint256 = Uint256(0, 0)
    let (is_positive) = uint256_lt(zero_as_uint256, amount_received)
    assert is_positive = 1

    let (final_balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = evaluator_address)

    let (difference) = uint256_sub(initial_balance, final_balance)
    let (amount_is_difference) = uint256_eq(amount_received, difference)

    # Checking if player has validated this exercise before
    let (has_validated) = has_validated_exercise(sender_address, 3)

    # This is necessary because of revoked references. Don't be scared, they won't stay around for too long...
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if has_validated == 0:
        # player has validated
        validate_exercise(sender_address, 3)
        # Sending points
        distribute_points(sender_address, 2)
    end
    return()
end


@external
func ex4_test_buy_token{syscall_ptr : felt *, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # We'll see about this one later
    return ()
end



@external
func ex5_test_deny_listing{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (sender_address) = get_caller_address()
    let (evaluator_address) = get_contract_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address)

    let (initial_balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = evaluator_address)
    let (amount_received) = IExerciseSolution.get_token(contract_address = submitted_exercise_address)
    # Checking returned value is 0
    let zero_as_uint256: Uint256 = Uint256(0, 0)
    let (difference) = uint256_sub(zero_as_uint256, amount_received)
    assert difference = zero_as_uint256

    # Checking that the balance didn't change
    let (final_balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = evaluator_address)
    let (amount_is_difference) = uint256_eq(initial_balance, final_balance)

    # Saving contract that denied the token request
    first_listing_storage.write(submitted_exercise_address, 1)

    # Checking if player has validated this exercise before
    let (has_validated) = has_validated_exercise(sender_address, 5)

    # This is necessary because of revoked references. Don't be scared, they won't stay around for too long...
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if has_validated == 0:
        # player has validated
        validate_exercise(sender_address, 5)
        # Sending points
        distribute_points(sender_address, 1)
    end
    return()
end


@external
func ex6_test_allow_listing{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (sender_address) = get_caller_address()
    let (evaluator_address) = get_contract_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address)
    # Checking that ther player has validated the previous exercise with the same contract
    let (was_denied_before) = first_listing_storage.read(submitted_exercise_address)
    assert was_denied_before = 1

    let (initial_balance) = IERC20.balanceOf(contract_address=submitted_exercise_address, account=evaluator_address)
    let (amount_received) = IExerciseSolution.get_token(contract_address=submitted_exercise_address)

    # Checking that the returned value is positive
    let zero_as_uint256: Uint256 = Uint256(0, 0)
    let (positive) = uint256_lt(zero_as_uint256, amount_received)
    assert positive = 1

    # Checking that the balance did increase by that amount
    let (final_balance) = IERC20.balanceOf(contract_address=submitted_exercise_address, account=evaluator_address)
    let (difference) = uint256_sub(initial_balance, final_balance)
    let (amount_is_difference) = uint256_eq(amount_received, difference)

    # Checking if player has validated this exercise before
    let (has_validated) = has_validated_exercise(sender_address, 6)

    # This is necessary because of revoked references. Don't be scared, they won't stay around for too long...
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if has_validated == 0:
        # player has validated
        validate_exercise(sender_address, 6)
        # Sending points
        distribute_points(sender_address, 2)
    end
    return()
end


@external
func ex7_test_deny_listing{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (sender_address) = get_caller_address()
    let (evaluator_address) = get_contract_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address)

    let (initial_balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = evaluator_address)
    let (amount_received) = IExerciseSolution.get_token(contract_address = submitted_exercise_address)
    # Checking returned value is 0
    let zero_as_uint256: Uint256 = Uint256(0, 0)
    let (difference) = uint256_sub(zero_as_uint256, amount_received)
    assert difference = zero_as_uint256

    # Checking that the balance didn't change
    let (final_balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = evaluator_address)
    let (amount_is_difference) = uint256_eq(initial_balance, final_balance)

    # Saving contract that denied this token request
    first_listing_multi_storage.write(submitted_exercise_address, 1)

    # Checking if player has validated this exercise before
    let (has_validated) = has_validated_exercise(sender_address, 7)

    # This is necessary because of revoked references. Don't be scared, they won't stay around for too long...
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if has_validated == 0:
        # player has validated
        validate_exercise(sender_address, 7)
        # Sending points
        distribute_points(sender_address, 1)
    end
    return()
end


@external
func ex8_test_tier1_listing{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (sender_address) = get_caller_address()
    let (evaluator_address) = get_contract_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address)
    # Checking that ther player has validated the previous exercise with the same contract
    let (was_denied_before) = first_listing_multi_storage.read(submitted_exercise_address)
    assert was_denied_before = 1

    let (initial_balance) = IERC20.balanceOf(contract_address=submitted_exercise_address, account=evaluator_address)
    let (amount_received) = IExerciseSolution.get_token(contract_address=submitted_exercise_address)

    # Checking that the returned value is positive
    let zero_as_uint256: Uint256 = Uint256(0, 0)
    let (positive) = uint256_lt(zero_as_uint256, amount_received)
    assert positive = 1
    
    # Checking that the balance did increase by that amount
    let (final_balance) = IERC20.balanceOf(contract_address=submitted_exercise_address, account=evaluator_address)
    let (difference) = uint256_sub(initial_balance, final_balance)
    let (amount_is_difference) = uint256_eq(amount_received, difference)

    # Saving amount received from this address
    second_listing_multi_storage.write(submitted_exercise_address, amount_received)

    # Checking if player has validated this exercise before
    let (has_validated) = has_validated_exercise(sender_address, 8)

    # This is necessary because of revoked references. Don't be scared, they won't stay around for too long...
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if has_validated == 0:
        # player has validated
        validate_exercise(sender_address, 8)
        # Sending points
        distribute_points(sender_address, 2)
    end
    return()
end


@external
func ex9_test_tier2_listing{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (sender_address) = get_caller_address()
    let (evaluator_address) = get_contract_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address)

    # Checking that ther player has validated the previous exercise with the same contract
    let (first_ammount_received) = second_listing_multi_storage.read(submitted_exercise_address)
    let (initial_balance) = IERC20.balanceOf(contract_address=submitted_exercise_address, account=evaluator_address)
    let (second_amount_received) = IExerciseSolution.get_token(contract_address=submitted_exercise_address)

    # Checking that the returned value is positive
    let zero_as_uint256: Uint256 = Uint256(0, 0)
    let (positive) = uint256_lt(zero_as_uint256, second_amount_received)
    assert positive = 1

    # Checking that the balance did increase by that amount
    let (final_balance) = IERC20.balanceOf(contract_address=submitted_exercise_address, account=evaluator_address)
    let (difference) = uint256_sub(initial_balance, final_balance)
    let (amount_is_difference) = uint256_eq(second_amount_received, difference)

    # Checking received amount is twice the first amount
    let two_as_uint256: Uint256 = Uint256(2, 0)
    let twice_first_amount: Uint256 = uint256_mul(first_ammount_received, two_as_uint256)
    let (is_equal) = uint256_eq(second_amount_received, twice_first_amount)
    assert is_equal = 1

    # Checking if player has validated this exercise before
    let (has_validated) = has_validated_exercise(sender_address, 9)

    # This is necessary because of revoked references. Don't be scared, they won't stay around for too long...
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if has_validated == 0:
        # player has validated
        validate_exercise(sender_address, 9)
        # Sending points
        distribute_points(sender_address, 2)
    end
    return()
end


@external
func submit_exercise{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(erc20_address: felt):
    # Reading caller address
    let (sender_address) = get_caller_address()
    # Checking this contract was not used by another group before
    let (has_solution_been_submitted_before) = has_been_paired.read(erc20_address)
    assert has_solution_been_submitted_before = 0

    # Assigning passed ERC20 as player ERC20
    player_exercise_solution_storage.write(sender_address, erc20_address)
    has_been_paired.write(erc20_address, 1)

    # Checking if player has validated this exercise before
    let (has_validated) = has_validated_exercise(sender_address, 0)
    # This is necessary because of revoked references. Don't be scared, they won't stay around for too long...

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if has_validated == 0:
        # player has validated
        validate_exercise(sender_address, 0)
        # Sending Setup, contract & deployment points
        distribute_points(sender_address, 5)
    end
    return()
end

#
# Internal functions
#

func assign_rank_to_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(sender_address:felt):
    alloc_locals

    # Reading next available slot
    let (next_rank) = next_rank_storage.read()
    # Assigning to user
    assigned_rank_storage.write(sender_address, next_rank)

    let new_next_rank = next_rank + 1
    let (max_rank) = max_rank_storage.read()

    # Checking if we reach max_rank
    if new_next_rank == max_rank:
        next_rank_storage.write(0)
    else:
        next_rank_storage.write(new_next_rank)
    end
    return()
end


#
# External functions - Administration
# Only admins can call these. You don't need to understand them to finish the exercise.
#

@external
func set_random_values{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(values_len: felt, values: felt*, column: felt):
    only_teacher()
    # Check that we fill max_ranK_storage cells
    let (max_rank) = max_rank_storage.read()
    assert values_len = max_rank
    # Storing passed values in the store
    set_a_random_value(values_len, values, column)
    return()
end

#
# Internal functions - Administration
# Only admins can call these. You don't need to understand them to finish the exercise.
#

func set_a_random_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(values_len: felt, values: felt*, column: felt):
    if values_len == 0:
        # Start with sum=0.
        return ()
    end

    set_a_random_value(values_len=values_len - 1, values=values + 1, column=column)
    random_attributes_storage.write(column, values_len-1, [values])

    return ()
end
