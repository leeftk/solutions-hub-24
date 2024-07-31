// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DeMarket.sol";

contract DeMarketTest is Test {
    DeMarket public marketplace;
    address public alice = address(1);
    address public bob = address(0x2);

    function setUp() public {
        marketplace = new DeMarket();
        //deal bob and alice
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    /*//////////////////////////////////////////////////////////////
                          TEST RegisterAndList
    //////////////////////////////////////////////////////////////*/
    // Test registers a new user and then has that user list and item
    // test verifies the user and the item were registered correctly.
    // It then asserts that the information set for the item is correct.

    function testRegisterAndListItem() public {
        // Register a user and list an item
        vm.startPrank(alice);
        marketplace.registerUser("Alice");
        marketplace.listItem("Test Item", "A test item", 1 ether);
        vm.stopPrank();

        // Check that the user and item were registered correctly
        (string memory username, bool exists) = marketplace.users(alice);
        assertEq(username, "Alice");
        assertTrue(exists);

        // Check that the item was registered correctly
        (string memory name, string memory description, uint256 price, address owner) =
            marketplace.getItemInfo(1);
        assertEq(name, "Test Item");
        assertEq(description, "A test item");
        assertEq(price, 1 ether);
        assertEq(owner, alice);
    }

    /*//////////////////////////////////////////////////////////////
                          TEST purchasetItem
    //////////////////////////////////////////////////////////////*/
    // Test registers a new user and lists an item
    // test then registers a second user and has that user purchase the item
    // test verifies that owner of the item is the purchaser

    function testPurchaseItem() public {
        // Register a user and list an item
        vm.startPrank(alice);
        marketplace.registerUser("Alice");
        marketplace.listItem("Test Item", "A test item", 1 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        marketplace.registerUser("Bob");
        marketplace.purchaseItem{value: 1 ether}(1);
        vm.stopPrank();
        // Check that the item was purchased correctly
        bytes32 hash = keccak256(abi.encodePacked("Test Item", "A test item", uint256(1 * 10**18)));
        // check item mapping switched to false
        assertFalse(marketplace.itemListed(hash));
        (,,, address owner) = marketplace.getItemInfo(1);
        assertEq(owner, bob);
    }

    /*//////////////////////////////////////////////////////////////
                          TEST withdrawFunds
    //////////////////////////////////////////////////////////////*/
    // Test registers a new user and lists an item
    // test then registers a second user and has that user purchase the item
    // test then has the seller withdraw the funds
    // verifies that the seller balance is correct after the withdraw

    function testWithdrawFunds() public {
        // Register a user, list an item, and purchase it
        vm.startPrank(alice);
        marketplace.registerUser("Alice");
        marketplace.listItem("Test Item", "A test item", 1 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        marketplace.registerUser("Bob");
        marketplace.purchaseItem{value: 1 ether}(1);
        vm.stopPrank();

        uint256 initialBalance = alice.balance;
        // Seller withdraw funds
        vm.startPrank(alice);
        marketplace.withdrawFunds();
        vm.stopPrank();

        assertEq(alice.balance, initialBalance + 1 ether);
    }   
    /*//////////////////////////////////////////////////////////////
                          TEST purchaseHistory
    //////////////////////////////////////////////////////////////*/
    // Test registers a new user and lists two items
    // test then registers a second user and has that user purchase the item
    // test then has the seller withdraw the funds
    // verifies that the seller balance is correct after the withdraw

    function testPurchaseHistory() public {
        // Register users
        vm.startPrank(alice);
        marketplace.registerUser("Alice");
        marketplace.listItem("Item 1", "First item", 1 ether);
        marketplace.listItem("Item 2", "Second item", 2 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        marketplace.registerUser("Bob");

        // Bob purchases Item 1
        marketplace.purchaseItem{value: 1 ether}(1);

        // Bob purchases Item 2
        marketplace.purchaseItem{value: 2 ether}(2);

        // Check Bob's purchase history
        uint256[] memory purchaseHistory = marketplace.getUserPurchaseHistory(bob);
        assertEq(purchaseHistory.length, 2);
        assertEq(purchaseHistory[0], 1);
        assertEq(purchaseHistory[1], 2);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                          FUTURE TESTS
    //////////////////////////////////////////////////////////////*/

    // function testUserRegistrationFailsIfAlreadyRegistered() public {}
    // function testListItemFailsIfNotRegistered() public {}
    // function testListItemFailsIfNotEnoughFunds() public {}
    // function testRefundExcessPayment() public {}
    // function testWithdrawFundsFailsIfNotRegistered() public {}
    // and many more including... test all unhappy paths, 
    // event emission, edge cases, find invariants, fuzz tests etc.

    receive() external payable {}
}