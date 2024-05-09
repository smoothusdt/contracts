// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Routes Ananas payments
 * @dev Transfers tokens from the user to to the recipient + collects the fee.
 */
contract SmoothRouter {

    mapping (address => uint256) public nonces;

    function transfer(address tokenAddress, address from, address to, uint256 transferAmount, address feeCollector, uint256 feeAmount, uint256 nonce, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 digest = keccak256(abi.encodePacked("Smooth", block.chainid, address(this), tokenAddress, from, to, transferAmount, feeCollector, feeAmount, nonce));
        bytes32 prefixedDigest = keccak256(abi.encodePacked("\x19TRON Signed Message:\n32", digest));
        address signer = ecrecover(prefixedDigest, v, r, s);
        require(from == signer, "WRONG SIGNATURE");
        
        require(nonces[from] == nonce, "WRONG NONCE");
        nonces[from] += 1;
        
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(from, to, transferAmount);
        
        if (feeAmount > 0) {
            token.transferFrom(from, feeCollector, feeAmount);
        }
    }
}
