pragma solidity ^0.4.11;


import "./zeppelin/MintableToken.sol";
import "./Presale.sol";
import "./Token.sol";
import './zeppelin/MintableToken.sol';
import './zeppelin/SafeMath.sol';

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH baseRate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  Token public token;
  // The presale contract
  Presale public presale;
  // The presale token
  MintableToken public presaleToken;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public baseRate;

  // amount of raised money in wei
  uint256 public weiRaised;

  // amount of tokens created
  uint256 public tokensIssued;

  // Total number of  tokens
  uint256 constant public totalTokens = 1*10^9 * 10^18; // 18 decmals

  // // used for transfering presale tokens
  // uint256 public presaleAccountCount;
  // uint256 public presaleScanPosition;
  // uint256 public presaleRatioDecimal = 100; // change if presale has discount
  mapping (address => bool) presaleMigrated;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * event for token upgrade logging
   * @param upgrader user who is upgrading their presale tokens
   * @param amount amount of tokens upgraded
   */
  event TokenUpgraded(address indexed upgrader, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _presaleValue, address _presale, address _wallet) {
    require(_startTime >= now);
    require(_presaleValue > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _startTime + 30 days;
    baseRate = _presaleValue;
    wallet = _wallet;
    presale = Presale(_presale);
    // presaleAccountCount = presale.getAccountsCount();
    presaleToken = presale.token();
    // presaleScanPosition = 0; // Not required.
    // token.mint(ACCOUNT, AMOUNT) // TODO predistributed tokens go here
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (Token) {
    return new Token();
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // function to get current rate
  function getRate() public constant returns (uint256){
    if(now - startTime < 5 days){
      return baseRate;
    } else if (now - startTime < 10 days){
      return baseRate * 100 / 110;
    } else if (now - startTime < 15 days){
      return baseRate * 100 / 120;
    } else if (now - startTime < 20 days){
      return baseRate * 100 / 130;
    } else if (now - startTime < 25 days){
      return baseRate * 100 / 140;
    } else if (now - startTime < 30 days){
      return baseRate * 100 / 155;
    } else {
      return 0;
    }
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 rate = getRate();

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    tokensIssued = tokensIssued.add(tokens);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool tokenCapUnreached = msg.value * getRate() + tokensIssued < totalTokens;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && tokenCapUnreached;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

  function migrateBalances() public {
    require(!presaleMigrated[msg.sender]);

    uint256 presaleBalance = presaleToken.balanceOf(msg.sender);
    token.mint(msg.sender, presaleBalance);
    presaleMigrated[msg.sender] = true;

    TokenUpgraded(msg.sender, presaleBalance);
  }

  // function scanPresaleAccount(address _beneficiary) internal {
  //   uint256 presaleBalance = presaleToken.balanceOf(_beneficiary);

  //   // calculate token amount to be created
  //   uint256 tokens = presaleBalance.mul(presaleRatioDecimal).div(100);
  //   // uint256 tokens = 0;

  //   token.mint(_beneficiary, tokens);
  //   TokenUpgraded(_beneficiary, tokens);
  // }

  // function scanPresale(uint256 _count) public {
  //   uint256 iterations = 0;
  //   address account;
  //   while(iterations<_count && presaleScanPosition<presaleAccountCount){
  //     account = presale.getAccount(presaleScanPosition + iterations);
  //     scanPresaleAccount(account);
  //     Scanned(account);
  //     iterations = iterations + 1;
  //   }
  //   presaleScanPosition =  presaleScanPosition + iterations; // Update at end as an opt.
  // }

}
