pragma solidity ^0.4.15;

import "./zeppelin/MintableToken.sol";

contract PresaleToken is MintableToken {

  string public constant name = "Presale MOAT";
  string public constant symbol = "PMT";
  uint8 public constant decimals = 18;

  function transfer() public returns (bool) {
  	return false;
  }

  function transferFrom() public returns (bool) {
    return false;
  }

}