// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./SmoothProxy.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

contract SmoothAdmin  {

    struct Wallet {
        address signer;
        uint256 nonce;
    }

    // Maps wallet address to wallet data
    mapping(address => Wallet) public wallets;

    function createAndTransfer(
        address signer,
        bytes memory code,
        address tokenAddress,
        address from,
        address to,
        uint256 transferAmount,
        address feeCollector,
        uint256 feeAmount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        createWallet(signer, code);
        transfer(tokenAddress, from, to, transferAmount, feeCollector, feeAmount, nonce, v, r, s);
    }

    function createWallet(address signer, bytes memory code) public {
        bytes32 salt = bytes32(bytes20(signer));
        address walletAddress = Create2.deploy(0, salt, code);
        wallets[walletAddress] = Wallet(signer, 0);
    }

    function transfer(
        address tokenAddress,
        address from,
        address to,
        uint256 transferAmount,
        address feeCollector,
        uint256 feeAmount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        Wallet storage wallet = wallets[from];
        require(wallet.signer != address(0), "WALLET NOT CREATED");
        
        bytes32 digest = keccak256(abi.encodePacked("Smooth", block.chainid, address(this), tokenAddress, from, to, transferAmount, feeCollector, feeAmount, nonce));
        bytes32 prefixedDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));
        address signer = ecrecover(prefixedDigest, v, r, s);

        require(signer == wallet.signer, "WRONG SIGNER");
        require(nonce == wallet.nonce, "WRONG NONCE");

        wallet.nonce += 1;
        SmoothProxy(from).transfer(tokenAddress, to, transferAmount);

        if (feeAmount > 0) {
            SmoothProxy(from).transfer(tokenAddress, feeCollector, feeAmount);
        }
    }
}
