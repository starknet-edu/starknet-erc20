%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC20Solution:
    func get_tokens() -> (amount : Uint256):
    end

    func allowlist_level(account : felt) -> (level : felt):
    end

    func request_allowlist() -> (level_granted : felt):
    end

    func request_allowlist_level(level_requested : felt) -> (level_granted : felt):
    end
end
