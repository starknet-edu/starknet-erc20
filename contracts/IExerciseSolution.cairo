%lang starknet

from starkware.cairo.common.uint256 import Uint256


@contract_interface
namespace IExerciseSolution:
    func get_tokens_from_contract() -> (amount : Uint256):
    end
    func tokens_in_custody(account : felt) -> (amount : Uint256):
    end
    func withdraw_tokens() -> (amount: Uint256):
    end
end
