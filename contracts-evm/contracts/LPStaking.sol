
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
contract LPStaking is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 public immutable lpToken; IERC20 public immutable rewardToken;
    uint256 public rewardRatePerSec; uint256 public endTime; uint256 public lastUpdate; uint256 public accRewardPerShare;
    struct User { uint256 staked; uint256 rewardDebt; }
    mapping(address => User) public users;
    event Funded(uint256 amount, uint256 durationSec);
    constructor(address _lp, address _reward, address _owner) Ownable(_owner){ lpToken=IERC20(_lp); rewardToken=IERC20(_reward); lastUpdate=block.timestamp; }
    function fund(uint256 amount, uint256 durationSec) external onlyOwner whenNotPaused {
        _update(); require(durationSec>0,"duration=0"); rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        rewardRatePerSec = amount / durationSec; endTime = block.timestamp + durationSec; emit Funded(amount, durationSec);
    }
    function _update() internal { uint256 t = block.timestamp < endTime ? block.timestamp : endTime; if (t > lastUpdate) { uint256 s = lpToken.balanceOf(address(this)); if (s > 0) { accRewardPerShare += ((t - lastUpdate) * rewardRatePerSec * 1e18) / s; } lastUpdate = t; } }
    function pending(address u) public view returns (uint256) { User memory x = users[u]; uint256 a=accRewardPerShare; uint256 t = block.timestamp < endTime ? block.timestamp : endTime; if (t > lastUpdate) { uint256 s = lpToken.balanceOf(address(this)); if (s > 0) { a += ((t - lastUpdate) * rewardRatePerSec * 1e18) / s; } } return (x.staked*a)/1e18 - x.rewardDebt; }
    function deposit(uint256 amount) external nonReentrant whenNotPaused { _update(); User storage u = users[msg.sender]; if (u.staked > 0) { uint256 p = (u.staked * accRewardPerShare) / 1e18 - u.rewardDebt; if (p>0) rewardToken.safeTransfer(msg.sender, p);} if (amount > 0) { lpToken.safeTransferFrom(msg.sender, address(this), amount); u.staked += amount; } u.rewardDebt = (u.staked * accRewardPerShare) / 1e18; }
    function withdraw(uint256 amount) external nonReentrant { _update(); User storage u = users[msg.sender]; require(u.staked >= amount, "insufficient"); uint256 p = (u.staked * accRewardPerShare) / 1e18 - u.rewardDebt; if (p>0) rewardToken.safeTransfer(msg.sender, p); if (amount > 0) { u.staked -= amount; lpToken.safeTransfer(msg.sender, amount); } u.rewardDebt = (u.staked * accRewardPerShare) / 1e18; }
    function pause() external onlyOwner { _pause(); } function unpause() external onlyOwner { _unpause(); }
}
