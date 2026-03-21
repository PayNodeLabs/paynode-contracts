// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDC
 * @dev Simple ERC20 for POM Demo. 6 decimals to match real USDC.
 *      Public minting allowed for sandbox testing.
 */
contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "mUSDC") {}

    // 6 decimals to match USDC on Base
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @dev Mint tokens for testing. Publicly available for sandbox faucets.
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
