// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;


    /*//////////////////////////////////////////////////////////////
                               ERA IMPORTS
    //////////////////////////////////////////////////////////////*/
import {Test} from "forge-std/Test.sol";
import {ZkMinimalAccount} from "src/zksync/ZkMinimalAccount.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {
    Transaction,
    MemoryTransactionHelper
    } from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {BOOTLOADER_FORMAL_ADDRESS} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {ACCOUNT_VALIDATION_SUCCESS_MAGIC} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";

    /*//////////////////////////////////////////////////////////////
                               OZ IMPORTS
    //////////////////////////////////////////////////////////////*/
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract ZkMinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    ZkMinimalAccount minimalAccount;
    ERC20Mock usdc;

    uint256 constant AMOUNT = 1e18;
    bytes32 constant EMPTY_BYTES32 = bytes32(0);
    address constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        minimalAccount = new ZkMinimalAccount();
        minimalAccount.transferOwnership(ANVIL_DEFAULT_ACCOUNT);
        usdc = new ERC20Mock();
        vm.deal(address(minimalAccount), AMOUNT);
    }

    function testZkOwnerCanExecuteCommands() public {
        // Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        Transaction memory transaction = _createUnsignedTransaction(minimalAccount.owner(), 113, dest, value, functionData);

        // Act
        vm.prank(minimalAccount.owner());
        minimalAccount.executeTransaction(EMPTY_BYTES32, EMPTY_BYTES32, transaction);

        // Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testZkValidateTransaction() public {
        // Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);        

        Transaction memory transaction = _createUnsignedTransaction(minimalAccount.owner(), 113, dest, value, functionData);
        transaction = _signTransaction(transaction);

        // Act
        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        bytes4 magic = minimalAccount.validateTransaction(EMPTY_BYTES32, EMPTY_BYTES32, transaction);

        //Assert
        assertEq(magic, ACCOUNT_VALIDATION_SUCCESS_MAGIC); 
    }

    function testZkExecuteTransactionFromOutside() public {
        // Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);        

        Transaction memory transaction = _createUnsignedTransaction(minimalAccount.owner(), 113, dest, value, functionData);
        transaction = _signTransaction(transaction);

        // Act
        minimalAccount.executeTransactionFromOutside(transaction);

        // Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testZkInvalidSignatureReverts() public {
        // Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);        

        Transaction memory transaction = _createUnsignedTransaction(minimalAccount.owner(), 113, dest, value, functionData);
        // Sign with wrong private key (different from owner)
        uint256 wrongPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff81; // Different key
        transaction = _signTransactionWithKey(transaction, wrongPrivateKey);

        // Act & Assert
        vm.expectRevert(ZkMinimalAccount.ZkMinimalAccount__InvalidSignature.selector);
        minimalAccount.executeTransactionFromOutside(transaction);
    }

    function testZkInsufficientBalanceReverts() public {
        // Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);        

        Transaction memory transaction = _createUnsignedTransaction(minimalAccount.owner(), 113, dest, value, functionData);
        transaction = _signTransaction(transaction);

        // Remove all ETH from the account to trigger insufficient balance
        vm.deal(address(minimalAccount), 0);

        // Act & Assert
        vm.expectRevert(ZkMinimalAccount.ZkMinimalAccount__NotEnoughBalance.selector);
        minimalAccount.executeTransactionFromOutside(transaction);
    }

    function testZkNonBootloaderCannotValidate() public {
        // Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);        

        Transaction memory transaction = _createUnsignedTransaction(minimalAccount.owner(), 113, dest, value, functionData);
        transaction = _signTransaction(transaction);

        // Act & Assert - Try to call validateTransaction from non-bootloader address
        vm.expectRevert(ZkMinimalAccount.ZkMinimalAccount__NotFromBootLoader.selector);
        minimalAccount.validateTransaction(EMPTY_BYTES32, EMPTY_BYTES32, transaction);
    }

    function testZkNonBootloaderOrOwnerCannotExecute() public {
        // Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);        

        Transaction memory transaction = _createUnsignedTransaction(minimalAccount.owner(), 113, dest, value, functionData);
        address randomUser = makeAddr("randomUser");

        // Act & Assert - Try to call executeTransaction from non-bootloader and non-owner address
        vm.prank(randomUser);
        vm.expectRevert(ZkMinimalAccount.ZkMinimalAccount__NotFromBootLoaderOrOwner.selector);
        minimalAccount.executeTransaction(EMPTY_BYTES32, EMPTY_BYTES32, transaction);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/
    function _signTransaction(Transaction memory transaction) internal view returns (Transaction memory) {
        bytes32 unsignedTransactionHash = MemoryTransactionHelper.encodeHash(transaction);
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, unsignedTransactionHash);
        Transaction memory signedTransaction = transaction;
        signedTransaction.signature = abi.encodePacked(r, s, v);
        return signedTransaction;
    }

    function _signTransactionWithKey(Transaction memory transaction, uint256 privateKey) internal view returns (Transaction memory) {
        bytes32 unsignedTransactionHash = MemoryTransactionHelper.encodeHash(transaction);
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(privateKey, unsignedTransactionHash);
        Transaction memory signedTransaction = transaction;
        signedTransaction.signature = abi.encodePacked(r, s, v);
        return signedTransaction;
    }


    function _createUnsignedTransaction(address from, uint8 transactionType, address to, uint256 value, bytes memory data) internal view returns(Transaction memory) {
        uint256 nonce = vm.getNonce(address(minimalAccount));
        bytes32[] memory factoryDeps = new bytes32[](0);
        return Transaction({
            txType: transactionType, // We will use type 113 (0x71)
            from: uint256(uint160(from)),
            to: uint256(uint160(to)),
            gasLimit: 16777216,
            gasPerPubdataByteLimit: 16777216,
            maxFeePerGas: 16777216,
            maxPriorityFeePerGas: 16777216,
            paymaster: 0,
            nonce: nonce,
            value: value,
            reserved: [uint256(0), uint256(0), uint256(0), uint256(0)],
            data: data,
            signature: hex"",
            factoryDeps: factoryDeps,
            paymasterInput: hex"",
            reservedDynamic: hex""
        });
    }
}