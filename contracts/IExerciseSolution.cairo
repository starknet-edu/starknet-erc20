%lang starknet

from starkware.cairo.common.uint256 import Uint256


@contract_interface
namespace IExerciseSolution:
    # or return amount?
    func buyToken(value: Uint256) -> (success: felt): 
    end
     # or return amount?
    func getToken() -> (success: felt):
    end
end
