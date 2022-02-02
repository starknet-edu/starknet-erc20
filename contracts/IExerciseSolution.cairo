%lang starknet

from starkware.cairo.common.uint256 import Uint256


@contract_interface
namespace IExerciseSolution:
    func get_token() -> (amount : Uint256):
    end
end
