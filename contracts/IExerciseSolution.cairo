%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IExerciseSolution:
    func deposit_tokens(amount : Uint256) -> (total_amount : Uint256):
    end
    func get_tokens_from_contract() -> (amount : Uint256):
    end
    func tokens_in_custody(account : felt) -> (amount : Uint256):
    end
    func withdraw_tokens() -> (amount : Uint256):
    end
    func allowlist_level(account: felt) -> (level: felt)
    end
    func request_allowlist() -> (level_granted: felt)
    end
    func request_allowlist_level(level_requested: felt) -> (level_granted: felt)
    end
end
