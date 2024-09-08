// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RainIncentive {
    address public owner;
    uint256 public thresholdRainfall;
    uint256 public maxIncentive;
    bool public paused;
    mapping(address => bool) public registeredFarmers;
    mapping(address => uint256) public incentives;
    address[] public farmersList;

    event FarmerRegistered(address farmer);
    event FarmerRemoved(address farmer);
    event IncentiveDistributed(address farmer, uint256 amount);
    event FundsAdded(uint256 amount);
    event ContractPaused(bool isPaused);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(uint256 _threshold, uint256 _maxIncentive) payable {
        owner = msg.sender;
        thresholdRainfall = _threshold;
        maxIncentive = _maxIncentive;
    }

    function addFunds() external payable onlyOwner {
        emit FundsAdded(msg.value);
    }

    function registerFarmer(address _farmer) external onlyOwner whenNotPaused {
        require(!registeredFarmers[_farmer], "Farmer already registered");
        registeredFarmers[_farmer] = true;
        farmersList.push(_farmer);
        emit FarmerRegistered(_farmer);
    }

    function removeFarmer(address _farmer) external onlyOwner {
        require(registeredFarmers[_farmer], "Farmer not registered");
        registeredFarmers[_farmer] = false;
        for (uint i = 0; i < farmersList.length; i++) {
            if (farmersList[i] == _farmer) {
                farmersList[i] = farmersList[farmersList.length - 1];
                farmersList.pop();
                break;
            }
        }
        emit FarmerRemoved(_farmer);
    }

    function updateRainfallThreshold(uint256 _newThreshold) external onlyOwner {
        thresholdRainfall = _newThreshold;
    }

    function updateMaxIncentive(uint256 _newMaxIncentive) external onlyOwner {
        maxIncentive = _newMaxIncentive;
    }

    function checkRainfallAndDistribute(uint256 _rainfall) external onlyOwner whenNotPaused {
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
        return incentive > maxIncentive ? maxIncentive : incentive;
    }

    function withdrawIncentive() external whenNotPaused {
        require(registeredFarmers[msg.sender], "Not a registered farmer");
        uint256 amount = incentives[msg.sender];
        require(amount > 0, "No incentives available");

        incentives[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function getAllFarmers() external view returns (address[] memory) {
        return farmersList;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
        emit ContractPaused(paused);
    }

    receive() external payable {
        emit FundsAdded(msg.value);
    }
}
