
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./ITRC20.sol";
contract LPStaking {
  ITRC20 public lpToken; ITRC20 public rewardToken; address public owner;
  uint256 public rewardRatePerSec; uint256 public endTime; uint256 public lastUpdate; uint256 public accRewardPerShare;
  struct User { uint256 staked; uint256 rewardDebt; } mapping(address=>User) public users;
  modifier onlyOwner(){ require(msg.sender==owner,"!owner"); _; }
  constructor(address _lp, address _reward){ lpToken=ITRC20(_lp); rewardToken=ITRC20(_reward); owner=msg.sender; lastUpdate=block.timestamp; }
  function fund(uint256 amount, uint256 durationSec) external onlyOwner { _update(); require(durationSec>0,"duration=0"); require(rewardToken.transferFrom(msg.sender,address(this),amount),"fund fail"); rewardRatePerSec=amount/durationSec; endTime=block.timestamp+durationSec; }
  function _update() internal { uint256 t=block.timestamp<endTime?block.timestamp:endTime; if(t>lastUpdate){ uint256 s=lpToken.balanceOf(address(this)); if(s>0){ accRewardPerShare+=((t-lastUpdate)*rewardRatePerSec*1e18)/s; } lastUpdate=t; } }
  function pending(address u) public view returns(uint256){ User memory x=users[u]; uint256 a=accRewardPerShare; uint256 t=block.timestamp<endTime?block.timestamp:endTime; if(t>lastUpdate){ uint256 s=lpToken.balanceOf(address(this)); if(s>0){ a+=((t-lastUpdate)*rewardRatePerSec*1e18)/s; } } return (x.staked*a)/1e18 - x.rewardDebt; }
  function deposit(uint256 amount) external { _update(); User storage u=users[msg.sender]; if(u.staked>0){ uint256 p=(u.staked*accRewardPerShare)/1e18 - u.rewardDebt; if(p>0){ require(rewardToken.transfer(msg.sender,p),"claim fail"); } } if(amount>0){ require(lpToken.transferFrom(msg.sender,address(this),amount),"lp xfer fail"); u.staked+=amount; } u.rewardDebt=(u.staked*accRewardPerShare)/1e18; }
  function withdraw(uint256 amount) external { _update(); User storage u=users[msg.sender]; require(u.staked>=amount,"insufficient"); uint256 p=(u.staked*accRewardPerShare)/1e18 - u.rewardDebt; if(p>0){ require(rewardToken.transfer(msg.sender,p),"claim fail"); } if(amount>0){ u.staked-=amount; require(lpToken.transfer(msg.sender,amount),"lp xfer fail"); } u.rewardDebt=(u.staked*accRewardPerShare)/1e18; }
  function emergencyWithdraw() external { User storage u=users[msg.sender]; uint256 amt=u.staked; u.staked=0; u.rewardDebt=0; require(lpToken.transfer(msg.sender,amt),"lp xfer fail"); }
}
