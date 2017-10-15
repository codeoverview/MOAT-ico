pragma solidity ^0.4.15;

import "./zeppelin/Ownable.sol";

contract Whitelist is Ownable {
	mapping(address => bool) public whitelist;

	function addWhitelist(address[] _toWhitelist) onlyOwner public {
		uint256 len = _toWhitelist.length;
		for(uint i = 0; i<len; i++){
			whitelist[_toWhitelist[i]] = true;
		}
	}

	function removeWhitelist(address _toRemove) onlyOwner public {
		whitelist[_toRemove] = false;
	}

  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

}