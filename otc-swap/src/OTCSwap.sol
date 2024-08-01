// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// This contract allows two parties to swap tokens directly without a third party.

contract OTCSwap {
    using SafeERC20 for IERC20;

    error SwapAlreadyExecuted();
    error SwapExpired();
    error OnlyCounterpartyCanExecute();
    error OnlyInitiatorCanCancel();
    error ExpirationMustBeFuture();

    /*//////////////////////////////////////////////////////////////
                               STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(bytes32 => Swap) public swaps;

    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Swap {
        address initiator;
        address counterparty;
        address tokenXAddress;
        address tokenYAddress;
        uint256 amountX;
        uint256 amountY;
        uint256 expirationTime;
        bool executed;
    }

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event SwapCreated(bytes32 indexed swapId, address indexed initiator, address indexed counterparty);

    event SwapExecuted(bytes32 indexed swapId);

    event SwapCancelled(bytes32 indexed swapId);

    /*//////////////////////////////////////////////////////////////
                          FUNCTIONS - EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Initiates a swap with a specified counterparty, token pair, and amounts.
    /// @param _counterparty The address of the counterparty who can accept the swap.
    /// @param _tokenXAddress The contract address of token X being offered.
    /// @param _tokenYAddress The contract address of token Y being requested.
    /// @param _amountX The amount of token X being offered by the initiator.
    /// @param _amountY The amount of token Y expected from the counterparty.
    /// @param _expirationTime The timestamp by which the swap must be executed.
    /// @return swapId A unique identifier for the newly created swap.
    /// @dev The expiration time must be in the future at the time of swap creation.
    function createSwap(
        address _counterparty,
        address _tokenXAddress,
        address _tokenYAddress,
        uint256 _amountX,
        uint256 _amountY,
        uint256 _expirationTime
    ) external returns (bytes32) {
        if (_expirationTime < block.timestamp) revert ExpirationMustBeFuture();

        bytes32 swapId = keccak256(
            abi.encodePacked(
                msg.sender, _counterparty, _tokenXAddress, _tokenYAddress, _amountX, _amountY, _expirationTime
            )
        );

        swaps[swapId] = Swap({
            initiator: msg.sender,
            counterparty: _counterparty,
            tokenXAddress: _tokenXAddress,
            tokenYAddress: _tokenYAddress,
            amountX: _amountX,
            amountY: _amountY,
            expirationTime: _expirationTime,
            executed: false
        });

        emit SwapCreated(swapId, msg.sender, _counterparty);

        return swapId;
    }

    /// @notice Executes a swap, transferring the specified tokens.
    /// @param _swapId The identifier of the swap to be executed.
    /// @dev The function can only be called by the counterparty within the expiration time.
    function executeSwap(bytes32 _swapId) external {
        Swap storage swap = swaps[_swapId];
        if (swap.executed) revert SwapAlreadyExecuted();
        if (block.timestamp >= swap.expirationTime) revert SwapExpired();
        if (msg.sender != swap.counterparty) revert OnlyCounterpartyCanExecute();

        swap.executed = true;

        IERC20(swap.tokenXAddress).safeTransferFrom(swap.initiator, swap.counterparty, swap.amountX);
        IERC20(swap.tokenYAddress).safeTransferFrom(swap.counterparty, swap.initiator, swap.amountY);

        emit SwapExecuted(_swapId);
    }

    /// @notice Cancels a swap agreement that has not been executed yet.
    /// @param _swapId The unique identifier of the swap to be canceled.
    /// @dev Only the initiator of the swap can cancel it.
    function cancelSwap(bytes32 _swapId) external {
        Swap storage swap = swaps[_swapId];
        if (swap.executed) revert SwapAlreadyExecuted();
        if (msg.sender != swap.initiator) revert OnlyInitiatorCanCancel();

        delete swaps[_swapId];

        emit SwapCancelled(_swapId);
    }
}
