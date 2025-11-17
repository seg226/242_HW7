// addres: 0xbCd4496b4Ea214c36326FEcE5a62C40185a9A167
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 <=0.8.19.0;
import "@openzeppelin/contracts@4.9.3/token/ERC20/ERC20.sol";
/// @notice Token with faucet for grading purposes only
contract HawKoin is ERC20 {
    constructor() ERC20("HawKoin", "HAW") {
        _mint(msg.sender, 99999*1e18);
    }
    /// @notice In case anyone runs out of tokens.
    /// @dev Normally never do this, but it is fine for a class project.
    function mintMe(uint256 amount) external {
        _mint(msg.sender, amount*1e18);
    }
}