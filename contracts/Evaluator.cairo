######### ERC-20 evaluator
# Soundtrack https://www.youtube.com/watch?v=iuWa5wh8lG0

%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_lt, assert_not_zero

from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_mul, uint256_le, uint256_lt, uint256_check, uint256_eq, uint256_neg
)

from contracts.lib.SKNTD import (
    SKNTD_assert_uint256_difference, SKNTD_assert_uint256_eq, SKNTD_assert_uint256_le,
    SKNTD_assert_uint256_strictly_positive, SKNTD_assert_uint256_zero
)

from contracts.utils.ex00_base import (
    tderc20_address,
    ex_initializer,
    has_validated_exercise,
    validate_and_distribute_points_once,
    only_teacher,
    Teacher_accounts,
)

from contracts.token.ERC20.ITDERC20 import ITDERC20
from contracts.token.ERC20.IERC20 import IERC20

from contracts.IERC20Solution import IERC20Solution
from contracts.IExerciseSolution import IExerciseSolution

#
# Declaring storage vars
# Storage vars are by default not visible through the ABI. They are similar to "private" variables in Solidity
#

@storage_var
func dummy_token_address_storage() -> (dummy_token_address_storage : felt):
end

@storage_var
func max_rank_storage() -> (max_rank : felt):
end

@storage_var
func next_rank_storage() -> (next_rank : felt):
end

@storage_var
func random_attributes_storage(column : felt, rank : felt) -> (value : felt):
end

@storage_var
func assigned_rank_storage(player_address :  felt) -> (rank : felt):
end

# Part 1 is "ERC20", part 2 is "Exercise"
@storage_var
func has_been_paired(contract_address : felt, part : felt) -> (has_been_paired : felt):
end

@storage_var
func player_exercise_solution_storage(player_address : felt, part : felt) -> (contract_address : felt):
end

@storage_var
func exercise_claimed_for_amount_storage(submitted_exercise_address : felt) -> (amount : Uint256):
end

#
# Declaring getters
# Public variables should be declared explicitly with a getter
#

@view
func dummy_token_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (account : felt):
    let (address) = dummy_token_address_storage.read()
    return (address)
end

@view
func player_exercise_solution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_address : felt,
        part : felt) -> (contract_address : felt):
    let (contract_address) = player_exercise_solution_storage.read(player_address, part)
    return (contract_address)
end

@view
func next_rank{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (next_rank : felt):
    let (next_rank) = next_rank_storage.read()
    return (next_rank)
end

@view
func assigned_rank{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_address : felt) -> (rank : felt):
    let (rank) = assigned_rank_storage.read(player_address)
    return (rank)
end

@view
func read_ticker{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_address : felt) -> (ticker : felt):
    let (rank) = assigned_rank(player_address)
    let (ticker) = random_attributes_storage.read(0, rank)
    return (ticker)
end

@view
func read_supply{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_address : felt) -> (supply : Uint256):
    let (rank) = assigned_rank(player_address)
    let (supply_felt) = random_attributes_storage.read(1, rank)
    let supply : Uint256 = Uint256(supply_felt, 0)
    return (supply)
end


######### Constructor
# This function is called when the contract is deployed
#
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _players_registry : felt,
        _tderc20_address : felt,
        _dummy_token_address : felt,
        _workshop_id : felt,
        _first_teacher : felt):
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
func ex1_assign_rank{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # Allocating locals. Make your code easier to write and read by avoiding some revoked references
    alloc_locals

    # Reading caller address
    let (sender_address) = get_caller_address()

    assign_rank_to_player(sender_address)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 1, 1)
    return ()
end


@external
func ex2_test_erc20{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading caller address
    let (sender_address) = get_caller_address()
    
    # Retrieve expected characteristics
    let (expected_supply) = read_supply(sender_address)
    let (expected_symbol) = read_ticker(sender_address)

    # Retrieve player's erc20 solution address
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address, part=1)

    # Reading supply of submission address
    let (submission_supply) = IERC20.totalSupply(contract_address=submitted_exercise_address)
    # Checking supply is correct
    let (is_equal) = uint256_eq(submission_supply, expected_supply)
    assert  is_equal = 1

    # Reading symbol of submission address
    let (submission_symbol) = IERC20.symbol(contract_address=submitted_exercise_address)
    # Checking symbol is correct
    assert submission_symbol = expected_symbol
    
    # Checking some ERC20 functions were created
    let (evaluator_address) = get_contract_address()
    let (balance) = IERC20.balanceOf(contract_address=submitted_exercise_address, account=evaluator_address)
    let (initial_allowance) = IERC20.allowance(
        contract_address=submitted_exercise_address, owner=evaluator_address, spender=sender_address)

    # 10 tokens
    let ten_as_uint256 : Uint256 = Uint256(10 * 1000000000000000000, 0)
    IERC20.approve(contract_address=submitted_exercise_address, spender=sender_address, amount=ten_as_uint256)

    # Check that the allowance did raise by 10
    let (final_allowance) = IERC20.allowance(
        contract_address=submitted_exercise_address, owner=evaluator_address, spender=sender_address)

    # While we can assert that two felts are equal with `assert a = b`, it is a little longer for uint256:
    let (difference) = uint256_sub(final_allowance, initial_allowance)
    let (is_equal) = uint256_eq(difference, ten_as_uint256)
    assert is_equal = 1

    # The next line does the same in one line, we'll rather use that later on.
    # It is defined in `contracts/lib/SKNTD.cairo` with similar ones to assert equality, positivity, etc.
    SKNTD_assert_uint256_difference(after=final_allowance, before=initial_allowance, expected_difference=ten_as_uint256)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 2, 2)
    return ()
end


@external
func ex3_test_get_tokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (sender_address) = get_caller_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address, part=1)

    # test_get_tokens verifies that the amount returned effectively matches the difference in the evaluator's balance.
    let (has_received_tokens, amount_received) = test_get_tokens(submitted_exercise_address)
    assert has_received_tokens = 1

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 3, 2)
    return ()
end


@external
func ex4_5_6_test_fencing{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (evaluator_address) = get_contract_address()
    let (sender_address) = get_caller_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address, part=1)

    # Check that Evaluator is not allowed to get tokens
    let (allowlist_level_eval) = IERC20Solution.allowlist_level(
        contract_address=submitted_exercise_address, account=evaluator_address)
    assert allowlist_level_eval = 0

    # Try to get token
    # test_get_tokens verifies that the amount returned effectively matches the difference in the evaluator's balance.
    let (has_received_tokens, _) = test_get_tokens(submitted_exercise_address)
    # Checking that nothing happened
    assert has_received_tokens = 0

    # Distributing points the first time this exercise is completed until this point
    validate_and_distribute_points_once(sender_address, 4, 1)

    # Get whitelisted by asking politely
    let (whitelisted) = IERC20Solution.request_allowlist(contract_address=submitted_exercise_address)
    assert whitelisted = 1
    validate_and_distribute_points_once(sender_address, 5, 1)

    # Check that Evaluator is whitelisted
    let (allowlist_level_eval) = IERC20Solution.allowlist_level(submitted_exercise_address, evaluator_address)
    assert_not_zero(allowlist_level_eval)

    # Check that we can now get tokens
    let (has_received_tokens, _) = test_get_tokens(submitted_exercise_address)
    assert has_received_tokens = 1

    # Distributing points the first time this exercise is completed until the end
    validate_and_distribute_points_once(sender_address, 6, 2)
    return ()
end


@external
func ex7_8_9_test_fencing_levels{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (evaluator_address) = get_contract_address()
    let (sender_address) = get_caller_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address, part=1)

    # test_get_tokens verifies that the amount returned effectively matches the difference in the evaluator's balance.
    let (has_received, _) = test_get_tokens(submitted_exercise_address)
    assert has_received = 0

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 7, 1)

    # Get whitelisted at level 1
    let (level) = IERC20Solution.request_allowlist_level(contract_address=submitted_exercise_address, level_requested=1)
    assert level = 1

    # Check allowlist_level view reflects the same change
    let (allowlist_level_eval) = IERC20Solution.allowlist_level(submitted_exercise_address, evaluator_address)
    assert allowlist_level_eval = 1

    # test_get_tokens verifies that the amount returned effectively matches the difference in the evaluator's balance.
    let (has_received, first_amount_received) = test_get_tokens(submitted_exercise_address)
    assert has_received = 1

    # Distributing points the first time this exercise is completed until this point
    validate_and_distribute_points_once(sender_address, 8, 2)

    # Get whitelisted at level 2
    let (level) = IERC20Solution.request_allowlist_level(contract_address=submitted_exercise_address, level_requested=2)
    assert level = 2

    # Check allowlist_level view
    let (allowlist_level_eval) = IERC20Solution.allowlist_level(submitted_exercise_address, evaluator_address)
    assert allowlist_level_eval = 2

    # test_get_tokens verifies that the amount returned effectively matches the difference in the evaluator's balance.
    let (has_received, second_amount_received) = test_get_tokens(submitted_exercise_address)
    assert has_received = 1

    # Check that we received twice the amount received with level 1
    let two_as_uint256 : Uint256 = Uint256(2, 0)
    let twice_first_amount : Uint256 = uint256_mul(first_amount_received, two_as_uint256)


    SKNTD_assert_uint256_eq(second_amount_received, twice_first_amount)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 9, 2)
    return ()
end


# ########
# PART 2

@external
func ex10_claimed_tokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (sender_address) = get_caller_address()
    let (read_dtk_address) = dummy_token_address()

    let (dummy_token_balance) = IERC20.balanceOf(contract_address=read_dtk_address, account=sender_address)

    # Checking that the sender's dummy token balance is positive
    SKNTD_assert_uint256_strictly_positive(dummy_token_balance)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 10, 2)
    return ()
end


@external
func ex11_claimed_from_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (evaluator_address) = get_contract_address()
    let (sender_address) = get_caller_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address, part=2)
    let (read_dtk_address) = dummy_token_address()

    # Initial state
    let (initial_dtk_custody) = IExerciseSolution.tokens_in_custody(
        contract_address=submitted_exercise_address, account=evaluator_address)
    # Initial balance of ExerciseSolution (used to check that the faucet was called during this execution)
    let (initial_solution_dtk_balance) = IERC20.balanceOf(read_dtk_address, submitted_exercise_address)

    # Claiming tokens for the evaluator
    let (claimed_amount) = IExerciseSolution.get_tokens_from_contract(submitted_exercise_address)

    # Checking that the amount returned is positive
    SKNTD_assert_uint256_strictly_positive(claimed_amount)

    # Saving that amount to check it is the same we withdraw later
    exercise_claimed_for_amount_storage.write(submitted_exercise_address, claimed_amount)

    # Checking that the amount in custody increased
    let (final_dtk_custody) = IExerciseSolution.tokens_in_custody(
        contract_address=submitted_exercise_address, account=evaluator_address)
    let (custody_difference) = uint256_sub(final_dtk_custody, initial_dtk_custody)
    SKNTD_assert_uint256_strictly_positive(custody_difference)

    # Checking that the amount returned is the same as the custody balance increase
    SKNTD_assert_uint256_eq(custody_difference, claimed_amount)

    # Finally, checking that the balance of ExerciseSolution was also increased by the same amount
    let (final_solution_dtk_balance) = IERC20.balanceOf(read_dtk_address, submitted_exercise_address)
    SKNTD_assert_uint256_difference(
        final_solution_dtk_balance, initial_solution_dtk_balance, custody_difference)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 11, 3)
    return ()
end


@external
func ex12_withdraw_from_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (evaluator_address) = get_contract_address()
    let (sender_address) = get_caller_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address, part=2)
    let (read_dtk_address) = dummy_token_address_storage.read()

    ############### Initial state
    # Initial balance of ExerciseSolution that will be used to check that its balance decreased in this tx
    let (initial_dtk_balance_submission) = IERC20.balanceOf(dummy_token_address, submitted_exercise_address)

    # Initial balance of Evaluator
    let (initial_dtk_balance_eval) = IERC20.balanceOf(read_dtk_address, evaluator_address)

    # Initial amount in custody of ExerciseSolution for Evaluator
    let (initial_dtk_custody) = IExerciseSolution.tokens_in_custody(
        contract_address=submitted_exercise_address, account=evaluator_address)

    ############### Actions
    # Withdrawing tokens claimed in previous exercise
    let (withdrawn_amount) = IExerciseSolution.withdraw_tokens(contract_address=submitted_exercise_address)

    # Checking that the amount is equal to the amount claimed in previous exercise
    let (claimed_amount) = exercise_claimed_for_amount_storage.read(submitted_exercise_address)
    SKNTD_assert_uint256_eq(withdrawn_amount, claimed_amount)

    ############### Balances checks
    # Checking that the evaluator's balance is now increased by `withdrawn_amount`
    let (final_dtk_balance_eval) = IERC20.balanceOf(read_dtk_address, evaluator_address)
    SKNTD_assert_uint256_difference(final_dtk_balance_eval, initial_dtk_balance_eval, withdrawn_amount)

    # Checking that the balance of ExerciseSolution was also decreased by the same amount
    let (final_dtk_balance_submission) = IERC20.balanceOf(read_dtk_address, submitted_exercise_address)
    SKNTD_assert_uint256_difference(
        initial_dtk_balance_submission, final_dtk_balance_submission, withdrawn_amount)

    ############### Custody checks
    # And finally checking that the amount in custody was decreased by same amount
    let (final_dtk_custody) = IExerciseSolution.tokens_in_custody(
        contract_address=submitted_exercise_address, account=evaluator_address)
    SKNTD_assert_uint256_difference(initial_dtk_custody, final_dtk_custody, withdrawn_amount)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 12, 2)
    return ()
end

@external
func ex13_approved_exercise_solution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (sender_address) = get_caller_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address, part=2)
    let (read_dtk_address) = dummy_token_address_storage.read()

    # Check the dummy token allowance of ExerciseSolution
    let (submission_dtk_allowance) = IERC20.allowance(
        contract_address=read_dtk_address, owner=sender_address, spender=submitted_exercise_address)
    SKNTD_assert_uint256_strictly_positive(submission_dtk_allowance)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 13, 1)
    return ()
end


@external
func ex14_revoked_exercise_solution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (sender_address) = get_caller_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address, part=2)
    let (read_dtk_address) = dummy_token_address_storage.read()

    # Check the dummy token allowance of ExerciseSolution is zero
    let (submission_dtk_allowance) = IERC20.allowance(
        contract_address=read_dtk_address, owner=sender_address, spender=submitted_exercise_address)
    SKNTD_assert_uint256_zero(submission_dtk_allowance)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 14, 1)
    return ()
end


@external
func ex15_deposit_tokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (evaluator_address) = get_contract_address()
    let (sender_address) = get_caller_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address, part=2)
    let (read_dtk_address) = dummy_token_address_storage.read()

    ############### Initial state
    # Reading initial balances of DTK
    let (initial_dtk_balance_eval) = IERC20.balanceOf(read_dtk_address, evaluator_address)
    let (initial_dtk_balance_submission) = IERC20.balanceOf(read_dtk_address, submitted_exercise_address)

    # Reading initial amount of DTK in custody of ExerciseSolution for Evaluator
    let (initial_dtk_custody) = IExerciseSolution.tokens_in_custody(
        contract_address=submitted_exercise_address, account=evaluator_address)

    ############### Actions
    # Allow ExerciseSolution to spend 10 DTK of Evaluator
    let ten_as_uint256 : Uint256 = Uint256(10, 0)
    IERC20.approve(read_dtk_address, submitted_exercise_address, ten_as_uint256)

    # Deposit them into ExerciseSolution
    let (total_custody) = IExerciseSolution.deposit_tokens(
        contract_address=submitted_exercise_address, amount=ten_as_uint256)

    ############### Balances check
    # Check that ExerciseSolution's balance of DTK also increased by ten tokens
    let (final_dtk_balance_submission) = IERC20.balanceOf(read_dtk_address, submitted_exercise_address)
    SKNTD_assert_uint256_difference(
        final_dtk_balance_submission, initial_dtk_balance_submission, ten_as_uint256)

    # Check that Evaluator's balance of DTK decreased by ten tokens
    let (final_dtk_balance_eval) = IERC20.balanceOf(read_dtk_address, evaluator_address)
    SKNTD_assert_uint256_difference(
        initial_dtk_balance_eval, final_dtk_balance_eval, ten_as_uint256)

    ############### Allowance check
    # Check the dummy token allowance of ExerciseSolution is back to zero
    let (submission_dtk_allowance) = IERC20.allowance(
        contract_address=read_dtk_address, owner=sender_address, spender=submitted_exercise_address)
    SKNTD_assert_uint256_zero(submission_dtk_allowance)

    ############### Custody check
    # Check that the custody balance did increase by ten tokens
    let (final_dtk_custody) = IExerciseSolution.tokens_in_custody(submitted_exercise_address, evaluator_address)
    SKNTD_assert_uint256_difference(final_dtk_custody, initial_dtk_custody, ten_as_uint256)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 15, 2)
    return ()
end


@external
func ex16_create_ERC20{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (evaluator_address) = get_contract_address()
    let (sender_address) = get_caller_address()
    let (submitted_exercise_token_address) = player_exercise_solution_storage.read(sender_address, part=3)

    # Checking that ExerciseSolutionToken is an ERC20 and evaluator doesn't own any
    let (supply) = IERC20.totalSupply(contract_address=submitted_exercise_token_address)
    let (symbol) = IERC20.symbol(contract_address=submitted_exercise_token_address)

    let (balance) = IERC20.balanceOf(submitted_exercise_token_address, evaluator_address)
    SKNTD_assert_uint256_zero(balance)
    let (allowance) = IERC20.allowance(
        contract_address=submitted_exercise_token_address, owner=evaluator_address, spender=sender_address)
    SKNTD_assert_uint256_zero(allowance)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 16, 2)
    return ()
end


@external
func ex17_deposit_and_mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (evaluator_address) = get_contract_address()
    let (sender_address) = get_caller_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address, part=2)
    let (submitted_exercise_token_address) = player_exercise_solution_storage.read(sender_address, part=3)
    let (read_dtk_address) = dummy_token_address_storage.read()

    ############### Initial state
    # Reading ExerciseSolutionToken (est) supply and evaluator's initial balance
    let (initial_est_supply) = IERC20.totalSupply(submitted_exercise_token_address)
    let (initial_est_balance_eval) = IERC20.balanceOf(submitted_exercise_token_address, evaluator_address)

    # Reading initial balances of DTK
    let (initial_dtk_balance_eval) = IERC20.balanceOf(read_dtk_address, evaluator_address)
    let (initial_dtk_balance_submission) = IERC20.balanceOf(read_dtk_address, submitted_exercise_address)

    ############### Actions
    # Allow ExerciseSolution to spend 10 DTK of Evaluator
    let ten_as_uint256 : Uint256 = Uint256(10, 0)
    IERC20.approve(read_dtk_address, submitted_exercise_address, ten_as_uint256)

    # Deposit them into ExerciseSolution
    IExerciseSolution.deposit_tokens(contract_address=submitted_exercise_address, amount=ten_as_uint256)

    ############### Balances checks
    # Check that ExerciseSolution's balance of DTK also increased by ten tokens
    let (final_dtk_balance_submission) = IERC20.balanceOf(read_dtk_address, submitted_exercise_address)
    SKNTD_assert_uint256_difference(
        final_dtk_balance_submission, initial_dtk_balance_submission, ten_as_uint256)

    # Check that Evaluator's balance of DTK decreased by ten tokens
    let (final_dtk_balance_eval) = IERC20.balanceOf(read_dtk_address, evaluator_address)
    SKNTD_assert_uint256_difference(
        initial_dtk_balance_eval, final_dtk_balance_eval, ten_as_uint256)

    ############### Allowance check
    # Check the dummy token allowance of ExerciseSolution is back to zero
    let (submission_dtk_allowance) = IERC20.allowance(
        contract_address=read_dtk_address, owner=sender_address, spender=submitted_exercise_address)
    SKNTD_assert_uint256_zero(submission_dtk_allowance)

    ############### ExerciseSolutionToken checks
    let (final_est_supply) = IERC20.totalSupply(contract_address=submitted_exercise_token_address)
    let (minted_tokens) = uint256_sub(final_est_supply, initial_est_supply)

    # Check that evaluator's balance increased by the minted amount
    let (final_est_balance_eval) = IERC20.balanceOf(submitted_exercise_token_address, evaluator_address)
    SKNTD_assert_uint256_difference(final_est_balance_eval, initial_est_balance_eval, minted_tokens)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 17, 2)
    return ()
end


@external
func ex18_withdraw_and_burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Reading addresses
    let (evaluator_address) = get_contract_address()
    let (sender_address) = get_caller_address()
    let (submitted_exercise_address) = player_exercise_solution_storage.read(sender_address, part=2)
    let (submitted_exercise_token_address) = player_exercise_solution_storage.read(sender_address, part=3)
    let (read_dtk_address) = dummy_token_address_storage.read()

    ############### Initial state
    # Reading ExerciseSolutionToken (est) supply and evaluator's initial balance
    let (initial_est_supply) = IERC20.totalSupply(submitted_exercise_token_address)
    let (initial_est_balance_eval) = IERC20.balanceOf(submitted_exercise_token_address, evaluator_address)

    # Reading initial balances of DTK
    let (initial_dtk_balance_eval) = IERC20.balanceOf(read_dtk_address, evaluator_address)
    let (initial_dtk_balance_submission) = IERC20.balanceOf(read_dtk_address, submitted_exercise_address)

    ############### Actions
    # Allow ExerciseSolution to spend all evaluator's ExercisesSolutionTokens
    IERC20.approve(submitted_exercise_token_address, evaluator_address, initial_est_balance_eval)

    # Withdrawing tokens deposited in previous exercise
    let (withdrawn_amount) = IExerciseSolution.withdraw_tokens(contract_address=submitted_exercise_address)

    # Checking that the amount is at least equal to the amount deposited in previous exercise (10 tokens)
    let ten_tokens_uint256 : Uint256 = Uint256(10, 0)
    SKNTD_assert_uint256_le(ten_tokens_uint256, withdrawn_amount)

    ############### Balances checks
    # Checking that the evaluator's balance is now increased by `withdrawn_amount`
    let (final_dtk_balance_eval) = IERC20.balanceOf(read_dtk_address, evaluator_address)
    SKNTD_assert_uint256_difference(final_dtk_balance_eval, initial_dtk_balance_eval, withdrawn_amount)

    # Checking that the balance of ExerciseSolution was also decreased by the same amount
    let (final_dtk_balance_submission) = IERC20.balanceOf(read_dtk_address, submitted_exercise_address)
    SKNTD_assert_uint256_difference(
        initial_dtk_balance_submission, final_dtk_balance_submission, withdrawn_amount)

    ############### ExerciseSolutionToken checks
    let (final_est_supply) = IERC20.totalSupply(contract_address=submitted_exercise_token_address)
    let (burned_amount) = uint256_sub(initial_est_supply, final_est_supply)

    # Check that evaluator's balance decreased by the burned amount
    let (final_est_balance_eval) = IERC20.balanceOf(submitted_exercise_token_address, evaluator_address)
    SKNTD_assert_uint256_difference(initial_est_balance_eval, final_est_balance_eval, burned_amount)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 18, 2)
    return ()
end


# ###########
# Submissions

@external
func submit_erc20_solution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        erc20_address : felt):
    # Reading caller address
    let (sender_address) = get_caller_address()
    # Checking this contract was not used by another group before
    let (has_solution_been_submitted_before) = has_been_paired.read(erc20_address, 1)
    assert has_solution_been_submitted_before = 0

    # Assigning passed ERC20 as player ERC20
    player_exercise_solution_storage.write(sender_address, erc20_address, 1)
    has_been_paired.write(erc20_address, 1, 1)

    # Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 0, 5)
    return ()
end


@external
func submit_exercise_solution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        exercise_address : felt):
    # Reading caller address
    let (sender_address) = get_caller_address()
    # Checking this contract was not used by another group before
    let (has_solution_been_submitted_before) = has_been_paired.read(exercise_address, 2)
    assert has_solution_been_submitted_before = 0

    # Assigning passed ExerciseSolution to the player
    player_exercise_solution_storage.write(sender_address, exercise_address, 2)
    has_been_paired.write(exercise_address, 2, 1)
    return ()
end

@external
func submit_exercise_solution_token{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        exercise_address : felt):
    # Reading caller address
    let (sender_address) = get_caller_address()
    # Checking this contract was not used by another group before
    let (has_solution_been_submitted_before) = has_been_paired.read(exercise_address, 3)
    assert has_solution_been_submitted_before = 0

    # Assigning passed ExerciseSolutionToken to the player
    player_exercise_solution_storage.write(sender_address, exercise_address, 3)
    has_been_paired.write(exercise_address, 3, 1)
    return ()
end


#
# Internal functions
#

func assign_rank_to_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender_address : felt):
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
    return ()
end


#
# External functions - Administration
# Only admins can call these. You don't need to understand them to finish the exercise.
#

@external
func set_random_values{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}(values_len : felt, values : felt*, column : felt):
    only_teacher()
    # Check that we fill max_ranK_storage cells
    let (max_rank) = max_rank_storage.read()
    assert values_len = max_rank
    # Storing passed values in the store
    set_a_random_value(values_len, values, column)
    return ()
end

#
# Internal functions - Administration
# Only admins can call these. You don't need to understand them to finish the exercise.
#

func set_a_random_value{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr}(values_len : felt, values : felt*, column : felt):
    if values_len == 0:
        # Start with sum=0.
        return ()
    end
    set_a_random_value(values_len=values_len - 1, values=values + 1, column=column)
    random_attributes_storage.write(column, values_len-1, [values])
    return ()
end

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
