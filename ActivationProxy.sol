// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

/**
 * @title Helps activate accounts
 * @dev Batches account activation with energy rental to speed the activation up.
 * It fully mimics the interface os JustLend, with the only exception that the rentResource function
 * also sends 1 sun to the "to" address in order to activate it.
 */
contract ActivationProxy {
    address public constant admin = 0x685638D045ED70aeE15DDC90a422FaED8c9be87C;
    
    function getJustLendAddress() public view returns (address) {
        if(block.chainid == 2494104990) return 0x5cCb6BdE3F663cC84120D5a872cd0A46A72195Aa; // shasta
        
        // mainnet
        return 0xC60a6F5C81431c97ed01B61698b6853557f3afd4;
    }

    // Activate user account and give it energy to make approval
    function rentResource(address payable receiver, uint256 amount, uint256 resourceType) public payable {
        require(msg.sender == admin, "not admin");

        receiver.transfer(350000); // transfer 0.35 trx to activate and make it able to pay for approval bandwidth
        
        address justLend = getJustLendAddress();
        uint256 sunToSend = address(this).balance;
        bytes memory justLendPyload = abi.encodeWithSignature(
            "rentResource(address,uint256,uint256)",
            receiver,
            amount,
            resourceType
        );

        (bool success,) = payable(justLend).call{value: sunToSend}(justLendPyload);
        require(success, "justLend energy rental failed");
    }
    
    // Revoke energy rental from the user and return TRX to the admin
    function returnResource(address payable receiver, uint256 amount, uint256 resourceType) public {
        require(msg.sender == admin, "not admin");
        
        address justLend = getJustLendAddress();
        bytes memory justLendPyload = abi.encodeWithSignature(
            "returnResource(address,uint256,uint256)",
            receiver,
            amount,
            resourceType
        );

        (bool success,) = justLend.call(justLendPyload);
        require(success, "justLend energy revoking failed");
        
        uint256 sunToSend = address(this).balance;
        payable(msg.sender).transfer(sunToSend);
    }
    
    receive() external payable {}
}
