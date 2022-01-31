######### ERC-20 evaluator
# Soundtrack https://www.youtube.com/watch?v=iuWa5wh8lG0

%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

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
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_eq
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
func assigned_supply{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player_address: felt) -> (supply: felt):
    let (rank) = assigned_rank(player_address)
    let (supply) = random_attributes_storage.read(0, rank)
    return (supply)
end

@view
func assigned_symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player_address: felt) -> (symbol: felt):
    let (rank) = assigned_rank(player_address)
    let (symbol) = random_attributes_storage.read(1, rank)
    return (symbol)
end

######### Constructor
# This function is called when the contract is deployed
#
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _tderc20_address : felt, 
        _dummy_token_address: felt, 
        _players_registry: felt, 
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
func ex1_test_erc20{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
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
func ex2_test_erc20{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading caller address
    let (sender_address) = get_caller_address()
    
    # Retrieve expected characteristics
    let (expected_supply) = assigned_supply(sender_address)
    let expected_supply_uint256: Uint256 = Uint256(expected_supply, 0)

    let (expected_symbol) = assigned_symbol(sender_address)

    # Retrieve exercise address
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address)

    # Reading supply of submission address
    let (read_supply) = IERC20.totalSupply(contract_address = submitted_exercise_address)
    # Checking supply is correct
    assert read_supply = expected_supply_uint256

    # Reading symbol of submission address
    let (read_symbol) = IERC20.symbol(contract_address = submitted_exercise_address)
    # Checking symbol is correct
    assert read_symbol = expected_symbol
    
    # Checking some ERC20 functions were created
    let (contract_address) = get_contract_address()

    # Instantiating a zero in uint format
    let zero_as_uint256: Uint256 = Uint256(0,0)

    let (initial_allowance) = IERC20.allowance(contract_address = submitted_exercise_address, owner = contract_address, spender = sender_address)
    let (is_equal) = uint256_eq(initial_allowance, zero_as_uint256)
    assert is_equal = 1

    let (balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = contract_address)
    let (is_equal) = uint256_eq(balance, zero_as_uint256)
    assert is_equal = 1

    # 10 tokens
    let ten_tokens_as_uint256: Uint256 = Uint256(10 * 1000000000000000000, 0)

    IERC20.approve(contract_address = submitted_exercise_address, spender = sender_address, amount = ten_tokens_as_uint256)

    let (final_allowance) = IERC20.allowance(contract_address = submitted_exercise_address, owner = contract_address, spender = sender_address)
    let (is_equal) = uint256_eq(final_allowance, ten_tokens_as_uint256)
    assert is_equal = 1

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
func ex3_test_erc20{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (sender_address) = get_caller_address()
    let (evaluator_address) = get_contract_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address)
    assert_not_zero(submitted_exercise_address)

    let (initial_balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = evaluator_address)
    let (got_token) = IExerciseSolution.getToken(contract_address = submitted_exercise_address)
    assert got_token = 1

    let (final_balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = evaluator_address)

    let (increased) = uint256_le(initial_balance, final_balance)
    assert increased = 1

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


# For ex4 you need DTK20 tokens. Go get them (and give me some?)
@external
func ex4_test_erc20{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (sender_address) = get_caller_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address)
    assert_not_zero(submitted_exercise_address)

    let first_buy_amount: Uint256 = _test_buy_token(submitted_exercise_address)
    
    # Checking if player has validated this exercise before
    let (has_validated) = has_validated_exercise(sender_address, 4)

    # This is necessary because of revoked references. Don't be scared, they won't stay around for too long...
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if has_validated == 0:
        # player has validated
        validate_exercise(sender_address, 4)
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
        # Sending points
        distribute_points(sender_address, 2)
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


func _test_buy_token{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(submitted_exercise_address : felt) -> (first_buy_amount : Uint256):
    alloc_locals
    # Reading addresses
    let (evaluator_address) = get_contract_address()

    let (initial_balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = evaluator_address)
    
    let ten_tokens_as_uint256: Uint256 = Uint256(10 * 1000000000000000000, 0)
    let (bought) = IExerciseSolution.buyToken(contract_address = submitted_exercise_address, value = ten_tokens_as_uint256)
    assert bought = 1

    let (intermediate_balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = evaluator_address)
    
    # Save bought amount
    let first_buy_amount : Uint256 = uint256_sub(intermediate_balance, initial_balance)
    # Check that balance increased
    let zero_as_uint256: Uint256 = Uint256(0, 0)
    let (increased) = uint256_lt(zero_as_uint256, first_buy_amount)
    assert increased = 1    

    # Buy some more token
    let thirty_tokens_as_uint256: Uint256 = Uint256(30 * 1000000000000000000, 0)
    let (bought) = IExerciseSolution.buyToken(contract_address = submitted_exercise_address, value = thirty_tokens_as_uint256)
    assert (bought) = 1

    let (final_balance) = IERC20.balanceOf(contract_address = submitted_exercise_address, account = evaluator_address)

    # Save bought amount
    let second_buy_amount : Uint256 = uint256_sub(final_balance, intermediate_balance)
    # Check that balance increased again
    let (increased) = uint256_lt(zero_as_uint256, second_buy_amount)
    assert increased = 1    

    # Check that we didn't get the same amount from both calls
    let (difference) = uint256_lt(first_buy_amount, second_buy_amount)
    assert difference = 1

    return (first_buy_amount)
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
