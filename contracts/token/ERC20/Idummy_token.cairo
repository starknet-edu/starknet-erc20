%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IDTKERC20:
    func faucet() -> (amount : Uint256):
    end
end
