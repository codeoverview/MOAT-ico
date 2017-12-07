pragma solidity 0.4.18;

import "./zeppelin/MintableToken.sol";
import "./zeppelin/PausableToken.sol";


contract Token is MintableToken, PausableToken {
    string public constant name = "MOAT";
    string public constant symbol = "MOAT";
    uint8 public constant decimals = 18;
}