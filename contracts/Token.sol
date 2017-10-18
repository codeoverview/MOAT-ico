pragma solidity ^0.4.15;

import "./zeppelin/MintableToken.sol";
import "./zeppelin/PausableToken.sol";

contract Token is MintableToken, PausableToken{
	string public constant name = "MOAT";
	string public constant symbol = "MAT";
	uint8 public constant decimals = 18;
}