// ######## ERC-20 Tutorial Evaluator
// Soundtrack https://www.youtube.com/watch?v=iuWa5wh8lG0

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_lt, assert_not_zero

from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_mul,
    uint256_le,
    uint256_lt,
    uint256_check,
    uint256_eq,
    uint256_neg,
)

from contracts.lib.UTILS import (
    UTILS_assert_uint256_difference,
    UTILS_assert_uint256_eq,
    UTILS_assert_uint256_le,
    UTILS_assert_uint256_strictly_positive,
    UTILS_assert_uint256_zero,
    UTILS_assert_uint256_lt,
)

from contracts.utils.ex00_base import (
    tuto_erc20_address,
    ex_initializer,
    has_validated_exercise,
    validate_and_distribute_points_once,
    only_teacher,
    teacher_accounts,
    assigned_rank,
    assign_rank_to_player,
    random_attributes_storage,
    max_rank_storage,
)

from contracts.token.ERC20.ITUTOERC20 import ITUTOERC20
from contracts.token.ERC20.IDTKERC20 import IDTKERC20
from contracts.token.ERC20.IERC20 import IERC20

from contracts.IERC20Solution import IERC20Solution
from contracts.IExerciseSolution import IExerciseSolution

//
// Declaring storage vars
// Storage vars are by default not visible through the ABI. They are similar to "private" variables in Solidity
//

@storage_var
func dummy_token_address_storage() -> (dummy_token_address_storage: felt) {
}

// Part 1 is "ERC20", part 2 is "Exercise"
@storage_var
func has_been_paired(contract_address: felt) -> (has_been_paired: felt) {
}

@storage_var
func player_exercise_solution_storage(player_address: felt, part: felt) -> (
    contract_address: felt
) {
}

//
// Declaring getters
// Public variables should be declared explicitly with a getter
//

@view
func dummy_token_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    account: felt
) {
    let (address) = dummy_token_address_storage.read();
    return (address,);
}

@view
func player_exercise_solution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player_address: felt, part: felt
) -> (contract_address: felt) {
    let (contract_address) = player_exercise_solution_storage.read(player_address, part);
    return (contract_address,);
}

@view
func read_ticker{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player_address: felt
) -> (ticker: felt) {
    let (rank) = assigned_rank(player_address);
    let (ticker) = random_attributes_storage.read(rank, 0);
    return (ticker,);
}

@view
func read_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player_address: felt
) -> (supply: Uint256) {
    let (rank) = assigned_rank(player_address);
    let (supply_felt) = random_attributes_storage.read(rank, 1);
    let supply: Uint256 = Uint256(supply_felt, 0);
    return (supply,);
}

// ######## Constructor
// This function is called when the contract is deployed
//
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _players_registry: felt,
    _tuto_erc20_address: felt,
    _dummy_token_address: felt,
    _workshop_id: felt,
    _first_teacher: felt,
) {
    ex_initializer(_tuto_erc20_address, _players_registry, _workshop_id);
    dummy_token_address_storage.write(_dummy_token_address);
    teacher_accounts.write(_first_teacher, 1);
    // Hard coded value for now
    max_rank_storage.write(100);
    return ();
}

// ######## External functions
// These functions are callable by other contracts
//

@external
func ex1_assign_rank{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // Allocating locals. Make your code easier to write and read by avoiding some revoked references
    alloc_locals;

    // Reading caller address
    let (sender_address) = get_caller_address();

    assign_rank_to_player(sender_address);

    // Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 1, 1);
    return ();
}

@external
func ex2_test_erc20{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // Reading caller address
    let (sender_address) = get_caller_address();

    // Retrieve expected characteristics
    let (expected_supply) = read_supply(sender_address);
    let (expected_symbol) = read_ticker(sender_address);

    // Retrieve player's erc20 solution address
    let (submitted_exercise_address) = player_exercise_solution_storage.read(
        player_address=sender_address, part=1
    );

    // Reading supply of submission address
    let (submission_supply) = IERC20.totalSupply(contract_address=submitted_exercise_address);
    // Checking supply is correct
    let (is_equal) = uint256_eq(submission_supply, expected_supply);
    with_attr error_message("Supply does not match the assignement's request") {
        assert is_equal = 1;
    }

    // Reading symbol of submission address
    let (submission_symbol) = IERC20.symbol(contract_address=submitted_exercise_address);
    with_attr error_message("Ticker does not match the assignement's request") {
        // Checking symbol is correct
        assert submission_symbol = expected_symbol;
    }

    // Checking some ERC20 functions were created
    let (evaluator_address) = get_contract_address();
    let (balance) = IERC20.balanceOf(
        contract_address=submitted_exercise_address, account=evaluator_address
    );

    // 10 tokens
    let ten_tokens_uint256: Uint256 = Uint256(10 * 1000000000000000000, 0);
    // Check that the Evaluator can approve the spender to transfer ten tokens
    IERC20.approve(
        contract_address=submitted_exercise_address,
        spender=sender_address,
        amount=ten_tokens_uint256,
    );

    // Check that the allowance is now 10
    let (allowance) = IERC20.allowance(
        contract_address=submitted_exercise_address, owner=evaluator_address, spender=sender_address
    );

    // Assertions with Uint256 require a little more verbosity. We'll see more about that later on.
    let (is_equal) = uint256_eq(allowance, ten_tokens_uint256);
    assert is_equal = 1;

    // Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 2, 2);
    return ();
}

@external
func ex3_test_get_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // Reading addresses
    let (sender_address) = get_caller_address();
    let (submitted_exercise_address) = player_exercise_solution_storage.read(
        player_address=sender_address, part=1
    );

    // test_get_tokens includes a check that the amount returned effectively matches the difference in the evaluator's
    // balance.  See its implementation at the bottom of this file.
    let (has_received_tokens, amount_received) = test_get_tokens(submitted_exercise_address);

    with_attr error_message("No tokens received") {
        assert has_received_tokens = 1;
    }

    // Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 3, 2);
    return ();
}

@external
func ex4_5_6_test_fencing{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // Reading addresses
    let (evaluator_address) = get_contract_address();
    let (sender_address) = get_caller_address();
    let (submitted_exercise_address) = player_exercise_solution_storage.read(
        player_address=sender_address, part=1
    );

    // Check that Evaluator is not allowed to get tokens
    let (allowlist_level_eval) = IERC20Solution.allowlist_level(
        contract_address=submitted_exercise_address, account=evaluator_address
    );

    with_attr error_message("Allowlist_level did not return 0 initially") {
        assert allowlist_level_eval = 0;
    }

    // Try to get token. We use `_` to show that we do not intend to use the second returned value.
    let (has_received_tokens, _) = test_get_tokens(submitted_exercise_address);

    // Checking that nothing happened
    with_attr error_message("It was possible to get tokens from the start") {
        assert has_received_tokens = 0;
    }

    // Get whitelisted by asking politely
    let (whitelisted) = IERC20Solution.request_allowlist(
        contract_address=submitted_exercise_address
    );

    with_attr error_message("request_allowlist did not return the correct value") {
        assert whitelisted = 1;
    }

    // Check that Evaluator is whitelisted
    let (allowlist_level_eval) = IERC20Solution.allowlist_level(
        submitted_exercise_address, evaluator_address
    );
    with_attr error_message("Allowlist_level did not return the correct value") {
        assert_not_zero(allowlist_level_eval);
    }
    // Check that we can now get tokens
    let (has_received_tokens, _) = test_get_tokens(submitted_exercise_address);

    with_attr error_message("Got no tokens when I should have") {
        assert has_received_tokens = 1;
    }

    // Distributing points the first time this exercise is completed
    // Implementing allow list view function
    validate_and_distribute_points_once(sender_address, 4, 1);
    // Implementing allow list management
    validate_and_distribute_points_once(sender_address, 5, 1);
    // Linking get tokens to allow list
    validate_and_distribute_points_once(sender_address, 6, 2);
    return ();
}

@external
func ex7_8_9_test_fencing_levels{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    alloc_locals;
    // Reading addresses
    let (evaluator_address) = get_contract_address();
    let (sender_address) = get_caller_address();
    let (submitted_exercise_address) = player_exercise_solution_storage.read(
        sender_address, part=1
    );

    // Check that we are initially not allowed to get tokens.
    let (has_received, _) = test_get_tokens(submitted_exercise_address);
    assert has_received = 0;

    // Get whitelisted at level 1
    let (level) = IERC20Solution.request_allowlist_level(
        contract_address=submitted_exercise_address, level_requested=1
    );
    assert level = 1;

    // Check allowlist_level view reflects the same change
    let (allowlist_level_eval) = IERC20Solution.allowlist_level(
        submitted_exercise_address, evaluator_address
    );
    assert allowlist_level_eval = 1;

    // Check that we received tokens, and retrieve how much
    let (has_received, first_amount_received) = test_get_tokens(submitted_exercise_address);
    assert has_received = 1;

    // Get whitelisted at level 2
    let (level) = IERC20Solution.request_allowlist_level(
        contract_address=submitted_exercise_address, level_requested=2
    );
    assert level = 2;

    // Check allowlist_level view
    let (allowlist_level_eval) = IERC20Solution.allowlist_level(
        submitted_exercise_address, evaluator_address
    );
    assert allowlist_level_eval = 2;

    // Check that we received tokens, and retrieve how much
    let (has_received, second_amount_received) = test_get_tokens(submitted_exercise_address);
    assert has_received = 1;

    // Check that we received more with level 2 than with level 1
    let (is_larger) = uint256_lt(first_amount_received, second_amount_received);
    assert is_larger = 1;

    // Now is a good time to introduce a few functions made for this tutorial.
    // While we can assert in cairo that a felt is smaller than another with `assert_lt(a, b)`,
    // it is a little longer for uint256. We've had to use this structure above in two lines of
    // code since the earlier exercises to compare Uint256 values.

    // The next line does the same and we'll rather use that for improved readability later on.
    // It is defined in `contracts/lib/UTILS.cairo` with similar ones to assert equality,
    // positivity, etc. UTILS is the library name, used to prevent name clashes, as described in
    // https://github.com/OpenZeppelin/cairo-contracts/blob/main/docs/Extensibility.md
    UTILS_assert_uint256_lt(first_amount_received, second_amount_received);

    // Distributing points the first time this exercise is completed
    // Denying claiming to non allowed contracts
    validate_and_distribute_points_once(sender_address, 7, 1);
    // Allowing level 1 claimers
    validate_and_distribute_points_once(sender_address, 8, 2);
    // Distributing more points to level 2 claimers
    validate_and_distribute_points_once(sender_address, 9, 2);
    return ();
}

// ########
// PART 2

@external
func ex10_claimed_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // Reading addresses
    let (sender_address) = get_caller_address();
    let (read_dtk_address) = dummy_token_address();

    let (dummy_token_balance) = IERC20.balanceOf(
        contract_address=read_dtk_address, account=sender_address
    );

    // Checking that the sender's dummy token balance is positive
    UTILS_assert_uint256_strictly_positive(dummy_token_balance);

    // Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 10, 2);
    return ();
}

@external
func ex11_claimed_from_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // Reading addresses
    let (evaluator_address) = get_contract_address();
    let (sender_address) = get_caller_address();
    let (submitted_exercise_address) = player_exercise_solution_storage.read(
        sender_address, part=2
    );
    let (read_dtk_address) = dummy_token_address();

    // Initial state
    let (initial_dtk_custody) = IExerciseSolution.tokens_in_custody(
        contract_address=submitted_exercise_address, account=evaluator_address
    );
    // Initial balance of ExerciseSolution (used to check that the faucet was called during this execution)
    let (initial_solution_dtk_balance) = IDTKERC20.balanceOf(
        read_dtk_address, submitted_exercise_address
    );

    // Claiming tokens for the evaluator
    let (claimed_amount) = IExerciseSolution.get_tokens_from_contract(submitted_exercise_address);

    // Checking that the amount returned is positive
    UTILS_assert_uint256_strictly_positive(claimed_amount);

    // Checking that the amount in custody increased
    let (final_dtk_custody) = IExerciseSolution.tokens_in_custody(
        contract_address=submitted_exercise_address, account=evaluator_address
    );
    let (custody_difference) = uint256_sub(final_dtk_custody, initial_dtk_custody);
    UTILS_assert_uint256_strictly_positive(custody_difference);

    // Checking that the amount returned is the same as the custody balance increase
    UTILS_assert_uint256_eq(custody_difference, claimed_amount);

    // Finally, checking that the balance of ExerciseSolution was also increased by the same amount
    let (final_solution_dtk_balance) = IDTKERC20.balanceOf(
        read_dtk_address, submitted_exercise_address
    );
    UTILS_assert_uint256_difference(
        final_solution_dtk_balance, initial_solution_dtk_balance, custody_difference
    );

    // Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 11, 3);
    return ();
}

@external
func ex12_withdraw_from_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    alloc_locals;
    // Reading addresses
    let (evaluator_address) = get_contract_address();
    let (sender_address) = get_caller_address();
    let (submitted_exercise_address) = player_exercise_solution_storage.read(
        sender_address, part=2
    );
    let (read_dtk_address) = dummy_token_address_storage.read();

    // ############## Initial state
    // Initial balance of ExerciseSolution that will be used to check that its balance decreased in this tx
    let (initial_dtk_balance_submission) = IDTKERC20.balanceOf(
        read_dtk_address, submitted_exercise_address
    );

    // Initial balance of Evaluator
    let (initial_dtk_balance_eval) = IDTKERC20.balanceOf(read_dtk_address, evaluator_address);

    // Initial amount in custody of ExerciseSolution for Evaluator
    let (initial_dtk_custody) = IExerciseSolution.tokens_in_custody(
        contract_address=submitted_exercise_address, account=evaluator_address
    );

    // ############## Actions
    // Withdrawing tokens claimed in previous exercise
    let (withdrawn_amount) = IExerciseSolution.withdraw_all_tokens(
        contract_address=submitted_exercise_address
    );

    // Checking that the amount is equal to the total evaluator balance in custody
    UTILS_assert_uint256_eq(withdrawn_amount, initial_dtk_custody);

    // ############## Balances checks
    // Checking that the evaluator's balance is now increased by `withdrawn_amount`
    let (final_dtk_balance_eval) = IDTKERC20.balanceOf(read_dtk_address, evaluator_address);
    UTILS_assert_uint256_difference(
        final_dtk_balance_eval, initial_dtk_balance_eval, withdrawn_amount
    );

    // Checking that the balance of ExerciseSolution was also decreased by the same amount
    let (final_dtk_balance_submission) = IDTKERC20.balanceOf(
        read_dtk_address, submitted_exercise_address
    );
    UTILS_assert_uint256_difference(
        initial_dtk_balance_submission, final_dtk_balance_submission, withdrawn_amount
    );

    // ############## Custody checks
    // And finally checking that the amount in custody was decreased by same amount
    let (final_dtk_custody) = IExerciseSolution.tokens_in_custody(
        contract_address=submitted_exercise_address, account=evaluator_address
    );
    UTILS_assert_uint256_difference(initial_dtk_custody, final_dtk_custody, withdrawn_amount);

    // Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 12, 2);
    return ();
}

@external
func ex13_approved_exercise_solution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    // Reading addresses
    let (sender_address) = get_caller_address();
    let (submitted_exercise_address) = player_exercise_solution_storage.read(
        sender_address, part=2
    );
    let (read_dtk_address) = dummy_token_address_storage.read();

    // Check the dummy token allowance of ExerciseSolution
    let (submission_dtk_allowance) = IERC20.allowance(
        contract_address=read_dtk_address, owner=sender_address, spender=submitted_exercise_address
    );
    UTILS_assert_uint256_strictly_positive(submission_dtk_allowance);

    // Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 13, 1);
    return ();
}

@external
func ex14_revoked_exercise_solution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    // Reading addresses
    let (sender_address) = get_caller_address();
    let (submitted_exercise_address) = player_exercise_solution_storage.read(
        sender_address, part=2
    );
    let (read_dtk_address) = dummy_token_address_storage.read();

    // Check the dummy token allowance of ExerciseSolution is zero
    let (submission_dtk_allowance) = IERC20.allowance(
        contract_address=read_dtk_address, owner=sender_address, spender=submitted_exercise_address
    );
    UTILS_assert_uint256_zero(submission_dtk_allowance);

    // Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 14, 1);
    return ();
}

@external
func ex15_deposit_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // Reading addresses
    let (evaluator_address) = get_contract_address();
    let (sender_address) = get_caller_address();
    let (submitted_exercise_address) = player_exercise_solution_storage.read(
        sender_address, part=2
    );
    let (read_dtk_address) = dummy_token_address_storage.read();

    // ############## Initial state
    // Reading initial balances of DTK
    let (initial_dtk_balance_eval) = IDTKERC20.balanceOf(read_dtk_address, evaluator_address);
    let (initial_dtk_balance_submission) = IDTKERC20.balanceOf(
        read_dtk_address, submitted_exercise_address
    );

    // Reading initial amount of DTK in custody of ExerciseSolution for Evaluator
    let (initial_dtk_custody) = IExerciseSolution.tokens_in_custody(
        contract_address=submitted_exercise_address, account=evaluator_address
    );

    // ############## Actions
    // Allow ExerciseSolution to spend 10 DTK of Evaluator
    let ten_tokens_uint256: Uint256 = Uint256(10 * 1000000000000000000, 0);
    IERC20.approve(read_dtk_address, submitted_exercise_address, ten_tokens_uint256);

    // Deposit them into ExerciseSolution
    let (total_custody) = IExerciseSolution.deposit_tokens(
        contract_address=submitted_exercise_address, amount=ten_tokens_uint256
    );

    // ############## Balances check
    // Check that ExerciseSolution's balance of DTK also increased by ten tokens
    let (final_dtk_balance_submission) = IDTKERC20.balanceOf(
        read_dtk_address, submitted_exercise_address
    );
    UTILS_assert_uint256_difference(
        final_dtk_balance_submission, initial_dtk_balance_submission, ten_tokens_uint256
    );

    // Check that Evaluator's balance of DTK decreased by ten tokens
    let (final_dtk_balance_eval) = IDTKERC20.balanceOf(read_dtk_address, evaluator_address);
    UTILS_assert_uint256_difference(
        initial_dtk_balance_eval, final_dtk_balance_eval, ten_tokens_uint256
    );

    // ############## Custody check
    // Check that the custody balance did increase by ten tokens
    let (final_dtk_custody) = IExerciseSolution.tokens_in_custody(
        submitted_exercise_address, evaluator_address
    );
    UTILS_assert_uint256_difference(final_dtk_custody, initial_dtk_custody, ten_tokens_uint256);

    // Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 15, 2);
    return ();
}

@external
func ex16_17_deposit_and_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // Reading addresses
    let (evaluator_address) = get_contract_address();
    let (sender_address) = get_caller_address();
    let (submitted_exercise_address) = player_exercise_solution_storage.read(
        sender_address, part=2
    );
    let (submitted_exercise_token_address) = IExerciseSolution.deposit_tracker_token(
        submitted_exercise_address
    );
    let (read_dtk_address) = dummy_token_address_storage.read();

    // ############## Initial state
    // Reading ExerciseSolutionToken (est) supply and evaluator's initial balance
    let (initial_est_supply) = IERC20.totalSupply(submitted_exercise_token_address);
    let (initial_est_balance_eval) = IERC20.balanceOf(
        submitted_exercise_token_address, evaluator_address
    );

    // Reading initial balances of DTK
    let (initial_dtk_balance_eval) = IDTKERC20.balanceOf(read_dtk_address, evaluator_address);
    let (initial_dtk_balance_submission) = IDTKERC20.balanceOf(
        read_dtk_address, submitted_exercise_address
    );

    // ############## Actions
    // Allow ExerciseSolution to spend 10 DTK of Evaluator
    let ten_tokens_uint256: Uint256 = Uint256(10 * 1000000000000000000, 0);
    IERC20.approve(read_dtk_address, submitted_exercise_address, ten_tokens_uint256);

    // Deposit them into ExerciseSolution
    IExerciseSolution.deposit_tokens(
        contract_address=submitted_exercise_address, amount=ten_tokens_uint256
    );

    // ############## Balances checks
    // Check that ExerciseSolution's balance of DTK also increased by ten tokens
    let (final_dtk_balance_submission) = IDTKERC20.balanceOf(
        read_dtk_address, submitted_exercise_address
    );
    UTILS_assert_uint256_difference(
        final_dtk_balance_submission, initial_dtk_balance_submission, ten_tokens_uint256
    );

    // Check that Evaluator's balance of DTK decreased by ten tokens
    let (final_dtk_balance_eval) = IDTKERC20.balanceOf(read_dtk_address, evaluator_address);
    UTILS_assert_uint256_difference(
        initial_dtk_balance_eval, final_dtk_balance_eval, ten_tokens_uint256
    );

    // ############## ExerciseSolutionToken checks
    let (final_est_supply) = IERC20.totalSupply(contract_address=submitted_exercise_token_address);
    let (minted_tokens) = uint256_sub(final_est_supply, initial_est_supply);

    // Check that evaluator's balance increased by the minted amount
    let (final_est_balance_eval) = IERC20.balanceOf(
        submitted_exercise_token_address, evaluator_address
    );
    UTILS_assert_uint256_difference(
        final_est_balance_eval, initial_est_balance_eval, minted_tokens
    );

    // Distributing points the first time this exercise is completed
    // Create and link ERC20
    validate_and_distribute_points_once(sender_address, 16, 2);
    // Tokenize custody
    validate_and_distribute_points_once(sender_address, 17, 2);
    return ();
}

@external
func ex18_withdraw_and_burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // Reading addresses
    let (evaluator_address) = get_contract_address();
    let (sender_address) = get_caller_address();
    let (submitted_exercise_address) = player_exercise_solution_storage.read(
        sender_address, part=2
    );
    let (submitted_exercise_token_address) = IExerciseSolution.deposit_tracker_token(
        submitted_exercise_address
    );
    let (read_dtk_address) = dummy_token_address_storage.read();

    // ############## Initial state
    // Reading ExerciseSolutionToken (est) supply and evaluator's initial balance
    let (initial_est_supply) = IERC20.totalSupply(submitted_exercise_token_address);
    let (initial_est_balance_eval) = IERC20.balanceOf(
        submitted_exercise_token_address, evaluator_address
    );

    // Reading initial balances of DTK
    let (initial_dtk_balance_eval) = IDTKERC20.balanceOf(read_dtk_address, evaluator_address);
    let (initial_dtk_balance_submission) = IDTKERC20.balanceOf(
        read_dtk_address, submitted_exercise_address
    );

    // ############## Actions
    // Allow ExerciseSolution to spend all evaluator's ExercisesSolutionTokens
    IERC20.approve(
        contract_address=submitted_exercise_token_address,
        spender=submitted_exercise_address,
        amount=initial_est_balance_eval,
    );

    // Withdrawing tokens deposited in previous exercise
    let (withdrawn_amount) = IExerciseSolution.withdraw_all_tokens(
        contract_address=submitted_exercise_address
    );

    // Checking that some money was withdrawn
    UTILS_assert_uint256_strictly_positive(withdrawn_amount);

    // ############## Balances checks
    // Checking that the evaluator's balance is now increased by `withdrawn_amount`
    let (final_dtk_balance_eval) = IDTKERC20.balanceOf(read_dtk_address, evaluator_address);
    UTILS_assert_uint256_difference(
        final_dtk_balance_eval, initial_dtk_balance_eval, withdrawn_amount
    );

    // Checking that the balance of ExerciseSolution was also decreased by the same amount
    let (final_dtk_balance_submission) = IDTKERC20.balanceOf(
        read_dtk_address, submitted_exercise_address
    );
    UTILS_assert_uint256_difference(
        initial_dtk_balance_submission, final_dtk_balance_submission, withdrawn_amount
    );

    // ############## ExerciseSolutionToken checks
    let (final_est_supply) = IERC20.totalSupply(contract_address=submitted_exercise_token_address);
    let (burned_amount) = uint256_sub(initial_est_supply, final_est_supply);

    // Check that evaluator's balance decreased by the burned amount
    let (final_est_balance_eval) = IERC20.balanceOf(
        submitted_exercise_token_address, evaluator_address
    );
    UTILS_assert_uint256_difference(
        initial_est_balance_eval, final_est_balance_eval, burned_amount
    );

    // Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 18, 2);
    return ();
}

// ###########
// Submissions

@external
func submit_erc20_solution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    erc20_address: felt
) {
    // Reading caller address
    let (sender_address) = get_caller_address();
    // Checking this contract was not used by another group before
    let (has_solution_been_submitted_before) = has_been_paired.read(erc20_address);
    assert has_solution_been_submitted_before = 0;

    // Assigning passed ERC20 as player ERC20
    player_exercise_solution_storage.write(
        player_address=sender_address, part=1, value=erc20_address
    );
    has_been_paired.write(erc20_address, 1);

    // Distributing points the first time this exercise is completed
    validate_and_distribute_points_once(sender_address, 0, 5);
    return ();
}

@external
func submit_exercise_solution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    exercise_address: felt
) {
    // Reading caller address
    let (sender_address) = get_caller_address();
    // Checking this contract was not used by another group before
    let (has_solution_been_submitted_before) = has_been_paired.read(exercise_address);
    assert has_solution_been_submitted_before = 0;

    // Assigning passed ExerciseSolution to the player
    player_exercise_solution_storage.write(
        player_address=sender_address, part=2, value=exercise_address
    );
    has_been_paired.write(exercise_address, 1);
    return ();
}

//
// Internal functions
//

func test_get_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tested_contract: felt
) -> (has_received_tokens: felt, amount_received: Uint256) {
    // This function will
    // * get initial evaluator balance on the given contract,
    // * call that contract's `get_tokens`
    // * get the evaluator's final balance
    // and return two values:
    // * Whether the evaluator's balance increased or not
    // * The balance difference (amount)
    // It will also make sure that the two values are consistent (asserts will fail otherwise)
    alloc_locals;
    let (evaluator_address) = get_contract_address();

    let (initial_balance) = IERC20.balanceOf(
        contract_address=tested_contract, account=evaluator_address
    );
    let (amount_received) = IERC20Solution.get_tokens(contract_address=tested_contract);

    // Checking returned value
    let zero_as_uint256: Uint256 = Uint256(0, 0);
    let (has_received_tokens) = uint256_lt(zero_as_uint256, amount_received);

    // Checking that current balance is initial_balance + amount_received (even if 0)
    let (final_balance) = IERC20.balanceOf(
        contract_address=tested_contract, account=evaluator_address
    );
    UTILS_assert_uint256_difference(final_balance, initial_balance, amount_received);

    return (has_received_tokens, amount_received);
}
