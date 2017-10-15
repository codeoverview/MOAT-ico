pragma solidity ^0.4.15;

import "./zeppelin/MintableToken.sol";

contract Token is MintableToken{
	string public constant name = "MOAT";
	string public constant symbol = "MAT";
	uint8 public constant decimals = 18;
}