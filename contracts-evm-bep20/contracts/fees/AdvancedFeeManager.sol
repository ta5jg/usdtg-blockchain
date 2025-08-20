// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IAdvancedFeeManager {
    function addFeeTier(uint256 _minAmount, uint256 _maxAmount, uint256 _feePercent) external;
    function removeFeeTier(uint256 index) external;
    function toggleDynamicFees() external;
    function getFeeTiers() external view returns (FeeTier[] memory);
    function isDynamicFeesEnabled() external view returns (bool);
}

struct FeeTier {
    uint256 minAmount;
    uint256 maxAmount;
    uint256 feePercent;
}

contract AdvancedFeeManager is IAdvancedFeeManager {
    address public admin;
    FeeTier[] public feeTiers;
    bool public dynamicFeesEnabled = false;

    event FeeTierAdded(uint256 minAmount, uint256 maxAmount, uint256 feePercent);
    event FeeTierRemoved(uint256 index);
    event DynamicFeesToggled(bool enabled);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor(address _admin) {
        require(_admin != address(0), "Invalid admin");
        admin = _admin;
    }

    function addFeeTier(uint256 _minAmount, uint256 _maxAmount, uint256 _feePercent) external override onlyAdmin {
        require(_minAmount < _maxAmount, "Invalid fee tier range");
        require(_feePercent <= 1000, "Fee too high"); // Max 10%
        
        feeTiers.push(FeeTier({
            minAmount: _minAmount,
            maxAmount: _maxAmount,
            feePercent: _feePercent
        }));
        
        emit FeeTierAdded(_minAmount, _maxAmount, _feePercent);
    }

    function removeFeeTier(uint256 index) external override onlyAdmin {
        require(index < feeTiers.length, "Invalid index");
        
        // Remove by swapping with last element
        feeTiers[index] = feeTiers[feeTiers.length - 1];
        feeTiers.pop();
        
        emit FeeTierRemoved(index);
    }

    function toggleDynamicFees() external override onlyAdmin {
        dynamicFeesEnabled = !dynamicFeesEnabled;
        emit DynamicFeesToggled(dynamicFeesEnabled);
    }

    function getFeeTiers() external view override returns (FeeTier[] memory) {
        return feeTiers;
    }

    function isDynamicFeesEnabled() external view override returns (bool) {
        return dynamicFeesEnabled;
    }

    // Test-only functions (bypass admin checks for testing)
    function addFeeTierForTesting(uint256 _minAmount, uint256 _maxAmount, uint256 _feePercent) external {
        require(_minAmount < _maxAmount, "Invalid fee tier range");
        require(_feePercent <= 1000, "Fee too high"); // Max 10%
        
        feeTiers.push(FeeTier({
            minAmount: _minAmount,
            maxAmount: _maxAmount,
            feePercent: _feePercent
        }));
        
        emit FeeTierAdded(_minAmount, _maxAmount, _feePercent);
    }
    
    function removeFeeTierForTesting(uint256 index) external {
        require(index < feeTiers.length, "Invalid index");
        
        // Remove by swapping with last element
        feeTiers[index] = feeTiers[feeTiers.length - 1];
        feeTiers.pop();
        
        emit FeeTierRemoved(index);
    }
    
    function toggleDynamicFeesForTesting() external {
        dynamicFeesEnabled = !dynamicFeesEnabled;
        emit DynamicFeesToggled(dynamicFeesEnabled);
    }
} 