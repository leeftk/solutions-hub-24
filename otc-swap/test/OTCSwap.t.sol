// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/OTCSwap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}

contract OTCSwapTest is Test {
    OTCSwap public otcSwap;
    MockERC20 public tokenX;
    MockERC20 public tokenY;
    address public alice;
    address public bob;

    function setUp() public {
        otcSwap = new OTCSwap();
        tokenX = new MockERC20("TokenX", "TKX");
        tokenY = new MockERC20("TokenY", "TKY");
        alice = address(0x1);
        bob = address(0x2);

        tokenX.transfer(alice, 1000000 * 10 ** 18);
        tokenY.transfer(bob, 1000000 * 10 ** 18);
    }

    /*//////////////////////////////////////////////////////////////
                          TEST CreateSwap
    //////////////////////////////////////////////////////////////*/

    // This test creates a swap with the initiator address
    // and the counterparty address, with the desired tokenX and tokenY
    // amounts, and the expiration time. It asserts the the values passed
    // in the createswap method are the same as the values stored in the
    // swap struct.
    // It also execute the swap and asserts that the alice and bobs balances
    // are updated correctly.

    function testCreateAndExecuteSwap() public {
        vm.startPrank(alice);
        bytes32 swapId = otcSwap.createSwap(
            bob, address(tokenX), address(tokenY), 100 * 10 ** 18, 200 * 10 ** 18, block.timestamp + 1 days
        );
        tokenX.approve(address(otcSwap), 100 * 10 ** 18);
        vm.stopPrank();

        (
            address initiator,
            address counterparty,
            ,
            ,
            uint256 amountX,
            uint256 amountY,
            uint256 expirationTime,
            bool executed
        ) = otcSwap.swaps(swapId);
        //assert swap created
        assertEq(initiator, alice);
        assertEq(counterparty, bob);
        assertEq(amountX, 100 * 10 ** 18);
        assertEq(amountY, 200 * 10 ** 18);
        assertEq(expirationTime, block.timestamp + 1 days);
        assertEq(executed, false);

        //execute swap
        vm.startPrank(bob);
        tokenY.approve(address(otcSwap), 200 * 10 ** 18);
        otcSwap.executeSwap(swapId);
        vm.stopPrank();

        //assert swap executed
        assertEq(tokenX.balanceOf(bob), 100 * 10 ** 18);
        assertEq(tokenY.balanceOf(alice), 200 * 10 ** 18);
    }
    /*//////////////////////////////////////////////////////////////
                          TEST executeExpiredSwap
    //////////////////////////////////////////////////////////////*/
    // This test attempts to execute a swap that has expired.
    // it does this by using vm.warp to move the block.timestamp forward
    // it then attempts to execute the swap and expects a revert.

    function testExecuteExpiredSwap() public {
        vm.startPrank(alice);
        bytes32 swapId = otcSwap.createSwap(
            bob, address(tokenX), address(tokenY), 100 * 10 ** 18, 200 * 10 ** 18, block.timestamp + 1 days
        );
        tokenX.approve(address(otcSwap), 100 * 10 ** 18);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);

        vm.startPrank(bob);
        tokenY.approve(address(otcSwap), 200 * 10 ** 18);
        vm.expectRevert();
        otcSwap.executeSwap(swapId);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                          TEST cancelSwap
    //////////////////////////////////////////////////////////////*/
    // This test creates a swap and then attempts to cancel it
    // before it is executed. It asserts that the swap initiator.
    // it asserts the initiator address is set to 0 after the swap is cancelled.

    function testCancelSwap() public {
        vm.startPrank(alice);
        bytes32 swapId = otcSwap.createSwap(
            bob, address(tokenX), address(tokenY), 100 * 10 ** 18, 200 * 10 ** 18, block.timestamp + 1 days
        );
        otcSwap.cancelSwap(swapId);
        vm.stopPrank();

        (address initiator,,,,,,,) = otcSwap.swaps(swapId);
        assertEq(initiator, address(0));
    }

    /*//////////////////////////////////////////////////////////////
                          TEST fuzzAmount
    //////////////////////////////////////////////////////////////*/
    // This test creates a swap with a random amount of tokenX
    // and then executes the swap. It then asserts that the contract
    // balance of tokenX and tokenY is zero. This test is a fuzz test
    // that does multiple runs with different amounts of tokenX.

    function testFuzzAmount(uint64 amountX) public {
        vm.startPrank(alice);
        bytes32 swapId =
            otcSwap.createSwap(bob, address(tokenX), address(tokenY), amountX, 10 * 10 ** 18, block.timestamp + 1 days);
        tokenX.approve(address(otcSwap), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenY.approve(address(otcSwap), type(uint256).max);
        otcSwap.executeSwap(swapId);
        vm.stopPrank();

        assertEq(tokenX.balanceOf(address(otcSwap)), 0);
        assertEq(tokenY.balanceOf(address(otcSwap)), 0);
    }

    /*//////////////////////////////////////////////////////////////
                          FUTURE TESTS
    //////////////////////////////////////////////////////////////*/

    /// function testFeeOnTransfer() public {}
    /// function testRevertIfSwapAlreadyExecuted() public {}
    /// function testRevertIfSwapExpired() public {}
    /// function testRevertIfNotCounterparty() public {}
    /// function testRevertIfNotInitiator() public {}
}
