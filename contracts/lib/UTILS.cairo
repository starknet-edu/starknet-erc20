# ######## Uint256 helpers for asserting amount changes

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_le, uint256_lt, uint256_sub

# UTILS_assert_uint256_X functions will trigger assertion errors, not return 0

func UTILS_assert_uint256_difference{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        after : Uint256, before : Uint256, expected_difference : Uint256):
    let (calculated_difference) = uint256_sub(after, before)
    let (calculated_is_expected) = uint256_eq(calculated_difference, expected_difference)
    assert calculated_is_expected = 1
    return ()
end

func UTILS_assert_uint256_eq{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        a : Uint256, b : Uint256):
    let (is_equal) = uint256_eq(a, b)
    assert is_equal = 1
    return ()
end

func UTILS_assert_uint256_le{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        a : Uint256, b : Uint256):
    let (is_le) = uint256_le(a, b)
    assert is_le = 1
    return ()
end

func UTILS_assert_uint256_lt{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        a : Uint256, b : Uint256):
    let (is_lt) = uint256_lt(a, b)
    assert is_lt = 1
    return ()
end

func UTILS_assert_uint256_not_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        a : Uint256):
    let zero : Uint256 = Uint256(0, 0)
    let (is_equal) = uint256_eq(a, zero)
    assert is_equal = 0
    return ()
end

func UTILS_assert_uint256_strictly_positive{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(a : Uint256):
    let zero : Uint256 = Uint256(0, 0)
    let (positive) = uint256_lt(zero, a)
    assert positive = 1
    return ()
end

func UTILS_assert_uint256_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        a : Uint256):
    let zero : Uint256 = Uint256(0, 0)
    let (is_equal) = uint256_eq(a, zero)
    assert is_equal = 1
    return ()
end
