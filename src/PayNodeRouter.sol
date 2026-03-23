// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title PayNodeRouter
 * @author AgentPay Protocol (PayNode Labs)
 * @notice This contract is licensed under Business Source License 1.1.
 *         Commercial use by competitors is restricted for the first 2 years.
 *
 * @dev Non-custodial, multi-coin payment router for the Agentic Economy.
 *      Stateless design ensures minimal gas costs (no SSTORE for order state).
 *      Protocol takes a fixed 1% fee (100 BPS).
 */
contract PayNodeRouter is Ownable2Step, Pausable {
    using SafeERC20 for IERC20;

    address public protocolTreasury;

    // Fixed protocol fee: 1% (100 basis points out of 10000)
    uint256 public constant PROTOCOL_FEE_BPS = 100;
    uint256 public constant MAX_BPS = 10000;
    uint256 public constant MIN_PAYMENT_AMOUNT = 1000;

    error InvalidAddress();
    error AmountTooLow();
    error UnauthorizedCaller();

    // Redesigned event to match SDK requirements (indexed orderId, token verification, chainId)
    event PaymentReceived(
        bytes32 indexed orderId,
        address indexed merchant,
        address indexed payer,
        address token,
        uint256 amount,
        uint256 fee,
        uint256 chainId
    );

    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    constructor(address _protocolTreasury) Ownable(msg.sender) {
        if (_protocolTreasury == address(0)) revert InvalidAddress();
        protocolTreasury = _protocolTreasury;
    }

    /**
     * @notice Allows the owner to update the protocol treasury address.
     * @param _newTreasury The new address for fee collection.
     */
    function updateTreasury(address _newTreasury) external onlyOwner {
        if (_newTreasury == address(0)) revert InvalidAddress();
        address old = protocolTreasury;
        protocolTreasury = _newTreasury;
        emit TreasuryUpdated(old, _newTreasury);
    }

    /**
     * @notice Pause the contract in case of emergencies
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Process an M2M payment for any ERC20 token. Payer must have already approved this contract.
     * @param token The ERC20 token address being used for payment (e.g. USDC, USDT).
     * @param merchant The address of the merchant receiving 99% of the funds.
     * @param amount The total payment amount.
     * @param orderId External tracking ID from the merchant's system (e.g., UUID mapped to bytes32).
     */
    function pay(address token, address merchant, uint256 amount, bytes32 orderId) external whenNotPaused {
        _processPayment(msg.sender, token, merchant, amount, orderId);
    }

    /**
     * @dev Process payment using EIP-2612 Permit. Solves the 2-step approve/transfer UX problem.
     *      Allows AI agents to sign locally and pay in a single on-chain transaction.
     */
    function payWithPermit(
        address payer,
        address token,
        address merchant,
        uint256 amount,
        bytes32 orderId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        if (msg.sender != payer) revert UnauthorizedCaller();

        // 1. Consume permit to grant allowance to this router
        IERC20Permit(token).permit(payer, address(this), amount, deadline, v, r, s);

        // 2. Execute the payment split
        _processPayment(payer, token, merchant, amount, orderId);
    }

    /**
     * @dev Internal split logic
     */
    function _processPayment(address payer, address token, address merchant, uint256 amount, bytes32 orderId) internal {
        if (merchant == address(0) || token == address(0)) revert InvalidAddress();
        if (amount < MIN_PAYMENT_AMOUNT) revert AmountTooLow();

        // Calculate 1% fee
        uint256 fee = (amount * PROTOCOL_FEE_BPS) / MAX_BPS;
        uint256 merchantAmount = amount - fee;

        // Execute atomic non-custodial transfers
        IERC20(token).safeTransferFrom(payer, merchant, merchantAmount);

        if (fee > 0) {
            IERC20(token).safeTransferFrom(payer, protocolTreasury, fee);
        }

        // Emit event for SDK webhook listeners
        emit PaymentReceived(orderId, merchant, payer, token, amount, fee, block.chainid);
    }
}
