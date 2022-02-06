%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC20Solution:
    func get_tokens() -> (amount : Uint256):
    end
    func get_whitelisted() -> (success : felt):
    end
    func get_whitelisted_tiers(requested_tier : felt) -> (allowed_tier : felt):
    end
end
