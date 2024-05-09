// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Routes Ananas payments
 * @dev Transfers tokens from the user to to the recipient + collects the fee.
 */
contract AnanasRouter {

    address public constant feeCollector = address(0xA49134Dfc6d89372E44b7e4369c025c6d535EeB0);
    IERC20 public constant USDT = IERC20(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);
    mapping (address => uint256) public nonces;

    function transfer(address from, address to, uint256 transferAmount, uint256 feeAmount, uint256 nonce, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 digest = keccak256(abi.encodePacked("Ananas", address(this), from, to, transferAmount, feeAmount, nonce));
        bytes32 prefixedDigest = keccak256(abi.encodePacked("\x19TRON Signed Message:\n32", digest));
        address signer = ecrecover(prefixedDigest, v, r, s);
        require(from == signer, "WRONG SIGNATURE");
        
        require(nonces[from] == nonce, "WRONG NONCE");
        nonces[from] += 1;
        
        USDT.transferFrom(from, to, transferAmount);
        
        if (feeAmount > 0) {
            USDT.transferFrom(from, feeCollector, feeAmount);
        }
    }
}
