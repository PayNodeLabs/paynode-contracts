// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract MockUSDC_EIP3009_Test is Test {
    MockUSDC public token;

    uint256 constant ALICE_KEY = 0xA11CE;
    uint256 constant BOB_KEY = 0xB0B;

    address public alice;
    address public bob;

    function setUp() public {
        alice = vm.addr(ALICE_KEY);
        bob = vm.addr(BOB_KEY);
        token = new MockUSDC();
        token.mint(alice, 1000e6);
    }

    function test_transferWithAuthorization() public {
        uint256 amount = 100e6;
        bytes32 nonce = keccak256("nonce-1");
        uint256 validBefore = block.timestamp + 1 hours;

        (uint8 v, bytes32 r, bytes32 s) = _signAuth(ALICE_KEY, alice, bob, amount, 0, validBefore, nonce);

        assertEq(token.balanceOf(alice), 1000e6);
        assertEq(token.balanceOf(bob), 0);

        token.transferWithAuthorization(alice, bob, amount, 0, validBefore, nonce, v, r, s);

        assertEq(token.balanceOf(alice), 900e6);
        assertEq(token.balanceOf(bob), 100e6);
    }

    function test_receiveWithAuthorization_revertIfNotRecipient() public {
        uint256 amount = 50e6;
        bytes32 nonce = keccak256("nonce-2");
        uint256 validBefore = block.timestamp + 1 hours;

        (uint8 v, bytes32 r, bytes32 s) = _signAuth(ALICE_KEY, alice, bob, amount, 0, validBefore, nonce);

        address charlie = vm.addr(0xC);
        vm.prank(charlie);
        vm.expectRevert("caller must be the recipient");
        token.receiveWithAuthorization(alice, bob, amount, 0, validBefore, nonce, v, r, s);
    }

    function test_cancelAuthorization() public {
        bytes32 nonce = keccak256("nonce-3");

        (uint8 v, bytes32 r, bytes32 s) = _signCancel(ALICE_KEY, alice, nonce);
        token.cancelAuthorization(alice, nonce, v, r, s);

        uint256 amount = 10e6;
        uint256 validBefore = block.timestamp + 1 hours;
        (uint8 v2, bytes32 r2, bytes32 s2) = _signAuth(ALICE_KEY, alice, bob, amount, 0, validBefore, nonce);

        vm.expectRevert("authorization already used");
        token.transferWithAuthorization(alice, bob, amount, 0, validBefore, nonce, v2, r2, s2);
    }

    function test_transferWithAuthorization_revertIfExpired() public {
        uint256 amount = 10e6;
        bytes32 nonce = keccak256("nonce-4");

        vm.warp(block.timestamp + 2 hours);
        uint256 validBefore = block.timestamp - 1 hours;

        (uint8 v, bytes32 r, bytes32 s) = _signAuth(ALICE_KEY, alice, bob, amount, 0, validBefore, nonce);

        vm.expectRevert("authorization is expired");
        token.transferWithAuthorization(alice, bob, amount, 0, validBefore, nonce, v, r, s);
    }

    function test_transferWithAuthorization_revertIfReused() public {
        uint256 amount = 10e6;
        bytes32 nonce = keccak256("nonce-5");
        uint256 validBefore = block.timestamp + 1 hours;

        (uint8 v, bytes32 r, bytes32 s) = _signAuth(ALICE_KEY, alice, bob, amount, 0, validBefore, nonce);

        token.transferWithAuthorization(alice, bob, amount, 0, validBefore, nonce, v, r, s);

        vm.expectRevert("authorization already used");
        token.transferWithAuthorization(alice, bob, amount, 0, validBefore, nonce, v, r, s);
    }

    function test_transferWithAuthorization_revertIfWrongSigner() public {
        uint256 amount = 10e6;
        bytes32 nonce = keccak256("nonce-6");
        uint256 validBefore = block.timestamp + 1 hours;

        (uint8 v, bytes32 r, bytes32 s) = _signAuth(BOB_KEY, alice, bob, amount, 0, validBefore, nonce);

        vm.expectRevert("invalid signature");
        token.transferWithAuthorization(alice, bob, amount, 0, validBefore, nonce, v, r, s);
    }

    function _signAuth(
        uint256 signerKey,
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 structHash = keccak256(
            abi.encode(token.TRANSFER_WITH_AUTHORIZATION_TYPEHASH(), from, to, value, validAfter, validBefore, nonce)
        );
        return _signEIP712(signerKey, structHash);
    }

    function _signCancel(uint256 signerKey, address authorizer, bytes32 nonce)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        bytes32 structHash = keccak256(abi.encode(token.CANCEL_AUTHORIZATION_TYPEHASH(), authorizer, nonce));
        return _signEIP712(signerKey, structHash);
    }

    function _signEIP712(uint256 signerKey, bytes32 structHash) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (v, r, s) = vm.sign(signerKey, digest);
    }
}
