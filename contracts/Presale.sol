pragma solidity ^0.4.11;

import './zeppelin/MintableToken.sol';
import './zeppelin/SafeMath.sol';
import './PresaleToken.sol';

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH baseRate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Presale {
  using SafeMath for uint256;

  // The token being sold
  PresaleToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  // uint256 public baseRate;

  // amount of raised money in wei
  uint256 public weiRaised;

  // mapping address to effective contributions
  mapping (address => uint256) contributions;

  // total contributions
  uint256 public totalContributions;

  // mapping address to if they have already claimed
  mapping (address => bool) claimedTokens;

  // Total number of presale tokens
  uint256 constant public totalTokens = 5*10^8 * 10^18; // 18 decmals

  // used for presale to ico migration
  // address[] accounts;
  // mapping(address => bool) public alreadyRegistered;

  // event Register(address account);

  /**
   * event for token purchase logging
   * @param purchaser who claimed the tokens
   * @param amount amount of tokens claimed
   */
  event TokenClaimed(address indexed purchaser, uint256 amount);
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param effectiveValue effective amount after discoutns
   */
  event WeiContributed(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 effectiveValue);


  function Presale(uint256 _startTime, address _wallet) {
    require(_startTime >= now);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _startTime + 12 days;
    wallet = _wallet;


  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (PresaleToken) {
    return new PresaleToken();
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // function gets the equivalent rate after bonuses
  function getRate() constant internal returns (uint256){
  	if(now - startTime < 2 days){
  		return 200;
  	} else if (now - startTime < 4 days){
  		return 190;
		} else if (now - startTime < 6 days){
			return 180;
		} else if (now - startTime < 8 days){
			return 170;
		} else if (now - startTime < 10 days){
			return 160;
		} else if (now - startTime < 12 days){
			return 150;
		} else {
			return 0;
		}
  }

  // low level token purchase function
  function buyTokens(address _beneficiary) public payable {
    require(_beneficiary != 0x0);
    require(validPurchase());

		// if(!alreadyRegistered[_beneficiary]){
		// 	alreadyRegistered[_beneficiary] = true;
		// 	accounts.push(_beneficiary);
		// 	Register(_beneficiary);
		// }

    uint256 weiAmount = msg.value;
    uint256 rate = getRate();
    uint256 effectiveAmount = (weiAmount * rate) / 100;
    contributions[_beneficiary] = contributions[_beneficiary] + effectiveAmount;

    // // calculate token amount to be created
    // uint256 tokens = weiAmount.mul(baseRate);

    // // update state
    weiRaised = weiRaised.add(weiAmount);
    totalContributions = totalContributions.add(effectiveAmount);

    // token.mint(_beneficiary, tokens);
    WeiContributed(msg.sender, _beneficiary, weiAmount, effectiveAmount);

    forwardFunds();
  }

  // used to claim tokens once preico ends
  function claimTokens() public {
  	require(now > endTime);
  	require(!claimedTokens[msg.sender]);

  	uint256 tokensPerWei = tokenValue();
  	uint256 userTokens = (contributions[msg.sender] * tokensPerWei);

  	token.mint(msg.sender, userTokens);
  	TokenClaimed(msg.sender, userTokens);
  }

  function tokenValue() public constant returns (uint256 tokensPerWei){
  	tokensPerWei = totalTokens / totalContributions;
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

  // // required to get length
  // function getAccountsCount() returns(uint256){
  // 	return accounts.length;
  // }

  // // contract deployment reports an error with public array variables, this is a workaround
  // function getAccount(uint256 _index) returns (address){
  // 	return accounts[_index];
  // }

}
