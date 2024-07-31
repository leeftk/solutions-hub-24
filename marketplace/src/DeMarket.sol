// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title DeMarket - Decentralized Marketplace
/// @author Lee Faria/33Audits
/// @notice Contract allows users to list, purchase, and withdraw funds from a decentralized marketplace.

contract DeMarket {
    error UserNotRegistered();
    error NoFundsToWithdraw();
    error WithdrawFailed();
    error UserAlreadyRegistered();
    error InsufficientFunds();
    error CannotPurchaseOwnItem();
    error ItemAlreadyListed();
    error ItemNotListed();
    /*//////////////////////////////////////////////////////////////
                               STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public itemCount;

    mapping(address user => User) public users;
    mapping(uint256 itemId => Item) public items;
    mapping(bytes32 hashes => bool duplicate) public itemListed;
    mapping(address user => uint256 balance) public userBalance;

    /// @dev Represents a user with a username, existence status, and purchase history.
    /// @param username The user's registered username.
    /// @param exists A bool indicating if the user exists.
    /// @param purchaseHistory An array of user's purchase history.
    struct User {
        string username;
        bool exists;
        uint256[] purchaseHistory;
    }

    /// @notice Represents an item with details like name, description, price, availability, and owner.
    /// @dev Struct to store item details.
    /// @param name The name of the item.
    /// @param description The description of the item.
    /// @param price The price of the item in wei.
    /// @param owner The address of the item's owner.
    struct Item {
        string name;
        string description;
        uint256 price;
        address owner;
    }

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRegistered(address indexed userAddress, string username);
    event ItemListed(uint256 indexed itemId, string name, uint256 price, address indexed owner);
    event ItemPurchased(uint256 indexed itemId, address indexed buyer, address indexed seller);
    event FundsWithdrawn(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Reverts with `UserNotRegistered` if the caller is not registered.
    modifier onlyRegisteredUser() {
        if (!users[msg.sender].exists) revert UserNotRegistered();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                          FUNCTIONS - EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Reverts with `UserAlreadyRegistered` if the user already exists.
    /// @param _username The username for the new user.
    function registerUser(string memory _username) external {
        if (users[msg.sender].exists) revert UserAlreadyRegistered();
        users[msg.sender] = User(_username, true, new uint256[](0));
        emit UserRegistered(msg.sender, _username);
    }

    /// @dev Lists a new item for sale.
    /// @param _name The name of the item.
    /// @param _description The description of the item.
    /// @param _price The price of the item in wei.
    function listItem(string memory _name, string memory _description, uint256 _price) external onlyRegisteredUser {
        bytes32 hashId = keccak256(abi.encodePacked(_name, _description, _price));
        if(itemListed[hashId]) revert ItemAlreadyListed();
        itemCount++;
        items[itemCount] = Item(_name, _description, _price, msg.sender);
        itemListed[hashId] = true;
        emit ItemListed(itemCount, _name, _price, msg.sender);
    }

    /// @dev Purchases an item.
    /// @param _itemId The ID of the item to purchase.
    function purchaseItem(uint256 _itemId) external payable onlyRegisteredUser {
        Item storage item = items[_itemId];
        bytes32 hashId = keccak256(abi.encodePacked(item.name, item.description, item.price));
        if(!itemListed[hashId]) revert ItemNotListed();
        if(msg.value < item.price) revert InsufficientFunds();
        if(msg.sender == item.owner) revert CannotPurchaseOwnItem();
        uint price = item.price;
        address seller = item.owner;
        itemListed[hashId] = false;
        item.owner = msg.sender;

        userBalance[seller] += price;

        // Add item to buyer's purchase history
        users[msg.sender].purchaseHistory.push(_itemId);

        // Refund excess payment
        if (msg.value > price) {
            (bool success,) = msg.sender.call{value: msg.value - price}("");
            if(!success) revert WithdrawFailed();
        }

        emit ItemPurchased(_itemId, msg.sender, seller);
    }

    /// @dev Withdraws accumulated funds.
    function withdrawFunds() external {
        if (!users[msg.sender].exists) revert UserNotRegistered();
        uint256 amount = userBalance[msg.sender];
        if (amount == 0) revert NoFundsToWithdraw();

        userBalance[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert WithdrawFailed();

        emit FundsWithdrawn(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                          FUNCTIONS - VIEW
    //////////////////////////////////////////////////////////////*/

    /// @dev Returnes information about specific item.
    /// @param _itemId The ID of the item.
    /// @return name Name of the item.
    /// @return description Description of the item.
    /// @return price Price of the item in wei.s
    /// @return owner The address of the item's owner.
    function getItemInfo(uint256 _itemId)
        external
        view
        returns (string memory, string memory, uint256, address)
    {
        Item storage item = items[_itemId];
        return (item.name, item.description, item.price, item.owner);
    }

    /// @dev Retrieves the purchase history of a user.
    /// @param _userAddress The address registered user.
    /// @return An array of item IDs representing the user's purchase history.
    function getUserPurchaseHistory(address _userAddress) external view onlyRegisteredUser returns (uint256[] memory) {
        return users[_userAddress].purchaseHistory;
    }
}
