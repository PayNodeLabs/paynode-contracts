// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PayNodeRouter} from "../src/PayNodeRouter.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

// Mock USDC/USDT with Permit for testing
contract MockToken is ERC20, ERC20Permit {
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) ERC20Permit(name) {
        _decimals = decimals_;
        _mint(msg.sender, 1000000 * 10 ** decimals_);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

contract PayNodeRouterTest is Test {
    PayNodeRouter public router;
    MockToken public usdc;
    MockToken public usdt;

    address public treasury = address(1);
    address public merchant = address(2);

    uint256 public payerPrivateKey = 0xA11CE;
    address public payer;

    event PaymentReceived(
        bytes32 indexed orderId,
        address indexed merchant,
        address indexed payer,
        address token,
        uint256 amount,
        uint256 fee,
        uint256 chainId
    );

    function setUp() public {
        payer = vm.addr(payerPrivateKey);

        // Mock Base USDC (6 decimals)
        usdc = new MockToken("Base USDC", "USDC", 6);
        // Mock Tether USD (6 decimals)
        usdt = new MockToken("Tether USD", "USDT", 6);

        router = new PayNodeRouter(treasury);

        // Mint initial balances
        usdc.mint(payer, 1000 * 10 ** 6);
        usdt.mint(payer, 1000 * 10 ** 6);
    }

    function test_Pay_USDC() public {
        uint256 paymentAmount = 100 * 10 ** 6;
        bytes32 orderId = keccak256("order_agent_001");

        vm.prank(payer);
        usdc.approve(address(router), paymentAmount);

        uint256 expectedFee = 1 * 10 ** 6;
        vm.expectEmit(true, true, true, true);
        emit PaymentReceived(orderId, merchant, payer, address(usdc), paymentAmount, expectedFee, block.chainid);

        vm.prank(payer);
        router.pay(address(usdc), merchant, paymentAmount, orderId);

        assertEq(usdc.balanceOf(merchant), 99 * 10 ** 6);
        assertEq(usdc.balanceOf(treasury), 1 * 10 ** 6);
    }

    function test_Pay_USDT() public {
        uint256 paymentAmount = 50 * 10 ** 6;
        bytes32 orderId = keccak256("order_agent_usdt_01");

        vm.prank(payer);
        usdt.approve(address(router), paymentAmount);

        uint256 expectedFee = 5 * 10 ** 5; // 0.5 USDT
        vm.expectEmit(true, true, true, true);
        emit PaymentReceived(orderId, merchant, payer, address(usdt), paymentAmount, expectedFee, block.chainid);

        vm.prank(payer);
        router.pay(address(usdt), merchant, paymentAmount, orderId);

        assertEq(usdt.balanceOf(merchant), 495 * 10 ** 5);
        assertEq(usdt.balanceOf(treasury), 5 * 10 ** 5);
    }

    function test_PayWithPermit_USDC() public {
        uint256 paymentAmount = 100 * 10 ** 6;
        bytes32 orderId = keccak256("order_agent_002");
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 permitTypehash =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        bytes32 structHash =
            keccak256(abi.encode(permitTypehash, payer, address(router), paymentAmount, usdc.nonces(payer), deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", usdc.DOMAIN_SEPARATOR(), structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(payerPrivateKey, digest);

        uint256 expectedFee = 1 * 10 ** 6;
        vm.expectEmit(true, true, true, true);
        emit PaymentReceived(orderId, merchant, payer, address(usdc), paymentAmount, expectedFee, block.chainid);

        // Use the payer as the caller to prevent MiTM issues as per router security logic
        vm.prank(payer);
        router.payWithPermit(payer, address(usdc), merchant, paymentAmount, orderId, deadline, v, r, s);

        assertEq(usdc.balanceOf(merchant), 99 * 10 ** 6);
        assertEq(usdc.balanceOf(treasury), 1 * 10 ** 6);
    }

    function testFuzz_Pay(uint256 amount, address fuzzMerchant) public {
        vm.assume(fuzzMerchant != address(0) && fuzzMerchant != treasury && fuzzMerchant != payer);
        vm.assume(amount >= 1000 && amount <= 1000000 * 10 ** 6);

        usdc.mint(payer, amount);

        bytes32 orderId = keccak256("fuzz_order");

        uint256 payerBalanceBefore = usdc.balanceOf(payer);
        uint256 merchantBalanceBefore = usdc.balanceOf(fuzzMerchant);
        uint256 treasuryBalanceBefore = usdc.balanceOf(treasury);

        vm.prank(payer);
        usdc.approve(address(router), amount);

        uint256 expectedFee = amount / 100;
        uint256 expectedMerchantAmt = amount - expectedFee;

        vm.prank(payer);
        router.pay(address(usdc), fuzzMerchant, amount, orderId);

        assertEq(usdc.balanceOf(fuzzMerchant), merchantBalanceBefore + expectedMerchantAmt);
        assertEq(usdc.balanceOf(treasury), treasuryBalanceBefore + expectedFee);
        assertEq(usdc.balanceOf(payer), payerBalanceBefore - amount);
    }

    function testFuzz_PayWithPermit(uint256 amount, address fuzzMerchant) public {
        vm.assume(fuzzMerchant != address(0) && fuzzMerchant != treasury && fuzzMerchant != payer);
        vm.assume(amount >= 1000 && amount <= 1000000 * 10 ** 6);

        // Mint extra to ensure enough balance for high fuzz amounts
        usdc.mint(payer, amount);

        bytes32 orderId = keccak256("fuzz_order_permit");
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 permitTypehash =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        bytes32 structHash =
            keccak256(abi.encode(permitTypehash, payer, address(router), amount, usdc.nonces(payer), deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", usdc.DOMAIN_SEPARATOR(), structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(payerPrivateKey, digest);

        uint256 treasuryBalanceBefore = usdc.balanceOf(treasury);

        vm.prank(payer);
        router.payWithPermit(payer, address(usdc), fuzzMerchant, amount, orderId, deadline, v, r, s);

        assertEq(usdc.balanceOf(treasury), treasuryBalanceBefore + (amount / 100));
    }
}
