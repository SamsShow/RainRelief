// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RainIncentiveTest {
    address public owner;
    uint256 public thresholdRainfall;
    mapping(address => bool) public registeredFarmers;
    mapping(address => uint256) public incentives;
    address[] public farmersList;

    event FarmerRegistered(address farmer);
    event IncentiveDistributed(address farmer, uint256 amount);
    event FundsAdded(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(uint256 _threshold) payable {
        owner = msg.sender;
        thresholdRainfall = _threshold;
    }

    function registerFarmer(address _farmer) external onlyOwner {
        require(!registeredFarmers[_farmer], "Farmer already registered");
        registeredFarmers[_farmer] = true;
        farmersList.push(_farmer);
        emit FarmerRegistered(_farmer);
    }

    function updateRainfallThreshold(uint256 _newThreshold) external onlyOwner {
        thresholdRainfall = _newThreshold;
    }

    function checkRainfallAndDistribute(uint256 _rainfall) external onlyOwner {
        require(_rainfall < thresholdRainfall, "Rainfall sufficient");

        for (uint256 i = 0; i < farmersList.length; i++) {
            address farmer = farmersList[i];
            if (registeredFarmers[farmer]) {
                uint256 incentiveAmount = calculateIncentive(_rainfall);
                incentives[farmer] += incentiveAmount;
                emit IncentiveDistributed(farmer, incentiveAmount);
            }
        }
    }

    function calculateIncentive(uint256 _rainfall) internal view returns (uint256) {
        uint256 deficit = thresholdRainfall - _rainfall;
        uint256 baseIncentive = 0.01 ether;
        uint256 incentive = baseIncentive * deficit;
        return incentive;
    }

    function withdrawIncentive() external {
        require(registeredFarmers[msg.sender], "Not a registered farmer");
        uint256 amount = incentives[msg.sender];
        require(amount > 0, "No incentives available");

        incentives[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}
