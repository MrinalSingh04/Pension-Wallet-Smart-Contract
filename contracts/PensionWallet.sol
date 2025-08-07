// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract PensionWallet {
    address public beneficiary;
    address public admin;
    uint256 public startTime;
    uint256 public vestingDuration;
    uint256 public totalAmount;
    uint256 public withdrawn;
    bool public paused;
    bool public emergencyUnlockApproved;

    event FundsDeposited(uint256 amount);
    event FundsWithdrawn(uint256 amount);
    event EmergencyUnlockApproved();
    event VestingPaused();
    event VestingResumed();

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only beneficiary");
        _;
    }

    constructor(address _beneficiary, uint256 _vestingDurationInYears) payable {
        require(msg.value > 0, "Initial deposit required");
        beneficiary = _beneficiary;
        admin = msg.sender;
        totalAmount = msg.value;
        vestingDuration = _vestingDurationInYears * 365 days;
        startTime = block.timestamp;
        withdrawn = 0;
    }

    function deposit() external payable onlyAdmin {
        totalAmount += msg.value;
        emit FundsDeposited(msg.value);
    }

    function pauseVesting() external onlyAdmin {
        paused = true;
        emit VestingPaused();
    }

    function resumeVesting() external onlyAdmin {
        paused = false;
        emit VestingResumed();
    }

    function approveEmergencyUnlock() external onlyAdmin {
        emergencyUnlockApproved = true;
        emit EmergencyUnlockApproved();
    }

    function vestedAmount() public view returns (uint256) {
        if (paused) return 0;
        if (block.timestamp >= startTime + vestingDuration) {
            return totalAmount;
        } else {
            uint256 elapsed = block.timestamp - startTime;
            return (totalAmount * elapsed) / vestingDuration;
        }
    }

    function withdraw() external onlyBeneficiary {
        uint256 available = vestedAmount() - withdrawn;

        require(available > 0 || emergencyUnlockApproved, "Nothing to withdraw");

        uint256 amountToWithdraw = emergencyUnlockApproved ? totalAmount - withdrawn : available;

        withdrawn += amountToWithdraw;
        payable(beneficiary).transfer(amountToWithdraw);
        emit FundsWithdrawn(amountToWithdraw);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
