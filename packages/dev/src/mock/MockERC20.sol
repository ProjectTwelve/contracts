// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "solady/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    /// @dev Returns the name of the token.
    function name() public view virtual override returns (string memory) {
        return "Test Token";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual override returns (string memory) {
        return "TT";
    }
}
