
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract USDTgTRC20 {
  string public name = "TetherGround USD";
  string public symbol = "USDTg";
  uint8 public decimals = 6;
  uint256 public totalSupply;
  address public owner;
  mapping(address=>uint256) public balanceOf;
  mapping(address=>mapping(address=>uint256)) public allowance;
  modifier onlyOwner(){ require(msg.sender==owner,"!owner"); _; }
  constructor(){ owner = msg.sender; }
  function transfer(address to, uint256 v) external returns(bool){ require(balanceOf[msg.sender]>=v,"bal"); balanceOf[msg.sender]-=v; balanceOf[to]+=v; return true; }
  function approve(address s,uint256 v) external returns(bool){ allowance[msg.sender][s]=v; return true; }
  function transferFrom(address f,address t,uint256 v) external returns(bool){ require(allowance[f][msg.sender]>=v,"allow"); require(balanceOf[f]>=v,"bal"); allowance[f][msg.sender]-=v; balanceOf[f]-=v; balanceOf[t]+=v; return true; }
  function mint(address to,uint256 v) external onlyOwner { totalSupply+=v; balanceOf[to]+=v; }
  function burn(uint256 v) external { require(balanceOf[msg.sender]>=v,"bal"); balanceOf[msg.sender]-=v; totalSupply-=v; }
}
