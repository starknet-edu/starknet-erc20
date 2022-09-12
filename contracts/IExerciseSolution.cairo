%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IExerciseSolution {
    func deposit_tokens(amount: Uint256) -> (total_amount: Uint256) {
    }

    func tokens_in_custody(account: felt) -> (amount: Uint256) {
    }

    func get_tokens_from_contract() -> (amount: Uint256) {
    }

    func withdraw_all_tokens() -> (amount: Uint256) {
    }

    func deposit_tracker_token() -> (deposit_tracker_token_address: felt) {
    }
}
