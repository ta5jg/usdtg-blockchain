// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../contracts/USDTgToken.sol";

contract TokenFuzzTest is Test {
    USDTgToken token;

    function setUp() public {
        token = new USDTgToken();
    }

    function testFuzz_Transfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount <= token.totalSupply());

        token.transfer(to, amount);
        assert(token.balanceOf(to) >= amount);
    }
}
