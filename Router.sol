// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

/**
 * @title Mocks JustLendDao energy rental smart contract.
 */
contract JustLendMock {
    struct RentalInfo {
        uint256 amount;
        uint256 securityDeposit;
        uint256 rentIndex;
    }
    
    uint256 public constant minFee = 40000000;
    uint256 public constant feeRatio = 500000000000000;
    uint256 public constant SCALE = 1e18;
    uint256 private rentalRate = 8896835225;
    mapping (address => mapping (address => RentalInfo)) private _rentals;
    mapping (address => mapping (address => uint256)) public lastUpdate;
    
    function rentals(address renter, address receiver, uint256 resourceType) public view returns (RentalInfo memory) {
        require(resourceType == 1, "resourceType must be 1 (energy)");
        RentalInfo memory rentalInfo = _rentals[renter][receiver];
        return rentalInfo;
    }
    
    function setRentalRate(uint256 newRentalRate) public {
        rentalRate = newRentalRate;
    }
    
    function _rentalRate(uint256 amount, uint256 resourceType) public view returns (uint256) {
        require(amount == 0, "amount must be 0");
        require(resourceType == 1, "resourceType must be 1 (energy)");
        return rentalRate;
    }
    
    function getRentInfo(address renter, address receiver, uint256 resourceType) public view returns (uint256, uint256, bool) {
        require(resourceType == 1, "resourceType must be 1 (energy)");
        RentalInfo memory rentalInfo = _rentals[renter][receiver];
        
        uint256 owedRent = _getOwedRent(renter, receiver);
        uint256 recalculatedSecurityDeposit = rentalInfo.securityDeposit - owedRent;
        
        // the "0" doesn't matter, but it's needed so that the returned result
        // is treated as array by tronWeb and not as an individual uint256.
        return (recalculatedSecurityDeposit, 0, false);
    }
    
    function _getOwedRent(address renter, address receiver) view public returns (uint256) {
        uint256 timeDelta = block.timestamp - lastUpdate[renter][receiver];
        uint256 owedRent = _rentals[renter][receiver].amount * rentalRate * timeDelta / SCALE;
        return owedRent;
    }
    
    function payRent(address renter, address receiver) public {
        uint256 owedRent = _getOwedRent(renter, receiver);
        _rentals[renter][receiver].securityDeposit -= owedRent;
        lastUpdate[renter][receiver] = block.timestamp;
    }
    
    function rentResource(address payable receiver, uint256 amount, uint256 resourceType) public payable {
       require(resourceType == 1, "resourceType must be 1 (energy)");

       _rentals[msg.sender][receiver].securityDeposit += msg.value;
       payRent(msg.sender, receiver);
       _rentals[msg.sender][receiver].amount += amount;

       if (amount > 0) {
          receiver.delegateResource(amount, resourceType);
       }
    }

    function returnResource(address payable receiver, uint256 amount, uint256 resourceType) public {
       require(resourceType == 1, "resourceType must be 1 (energy)");

       payRent(msg.sender, receiver);
       _rentals[msg.sender][receiver].amount -= amount;

       receiver.unDelegateResource(amount, resourceType);

       if (_rentals[msg.sender][receiver].amount <= 0) {
           _rentals[msg.sender][receiver].amount = 0;
           uint256 toWithdraw = _rentals[msg.sender][receiver].securityDeposit; // making an intermediary variable for security
           _rentals[msg.sender][receiver].securityDeposit = 0;
           payable(msg.sender).transfer(toWithdraw);
       }
    }

    function deposit() public payable {
        freezebalancev2(msg.value, 1);
    }
}
