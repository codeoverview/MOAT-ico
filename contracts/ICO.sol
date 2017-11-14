pragma solidity 0.4.15;

import "./Token.sol";
import "./zeppelin/SafeMath.sol";
import "./zeppelin/Ownable.sol";


/* solhint-disable not-rely-on-time */
/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH baseRate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract ICO is Ownable {
    using SafeMath for uint256;

    // The token being sold
    Token public token;

    // start and end timestamps where investments are allowed (both inclusive) ICO
    uint256 public startTimeIco;
    uint256 public endTimeIco;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public baseRate;

    // amount of raised money in wei
    uint256 public weiRaised;

    // amount of tokens created
    uint256 public tokensIssuedIco;

    // Total number of    tokens for the ICO
    uint256 constant public TOTAL_TOKENS_ICO = 125 * (10**7) * (10**18); // 18 decmals

    /**
    * Pre-ICO specific variables
    */

  // start and end timestamps where investments are allowed (both inclusive) PreIco
    uint256 public startTimePre;
    uint256 public endTimePre;

    // mapping address to effective contributions
    mapping (address => uint256) public contributions;

    // total contributions
    uint256 public totalContributions;

    // mapping address to if they have already claimed
    mapping (address => bool) public claimedTokens;

    // Total number of presale tokens
    uint256 constant public TOTAL_TOKENS_PRE = 25 * 10**7 * 10**18; // 18 decmals

    /**
      * event for token purchase logging
      * @param purchaser who paid for the tokens
      * @param beneficiary who got the tokens
      * @param value weis paid for purchase
      * @param amount amount of tokens purchased
      */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
      * event for token claimed from Pre-ICO
      * @param purchaser who claimed the tokens
      * @param amount amount of tokens claimed
      */
    event TokenClaimed(address indexed purchaser, uint256 amount);

    /**
      * event for wei contributed to Pre-ICO
      * @param purchaser who paid for the tokens
      * @param beneficiary who got the tokens
      * @param value weis paid for purchase
      * @param effectiveValue effective amount after discoutns
      */
    event WeiContributed(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 effectiveValue);

    function ICO(uint256 _startTimePre, uint256 _startTimeIco, address _wallet) public {
        require(_startTimePre >= block.timestamp);
        require(_startTimeIco >= _startTimePre);
        require(_wallet != 0x0);

        token = createTokenContract();
        startTimeIco = _startTimeIco;
        startTimePre = _startTimePre;
        endTimeIco = _startTimeIco + 30 days;
        endTimePre = _startTimePre + 12 days;
        wallet = _wallet;

        token.mint(0x8Faa64B6b2eD30290554128289f3A6De9A97D8F6, 4900000000);
        token.mint(0xe84f002ED596E38D7f1cE048503b13321eb28A98, 300000000);
        token.mint(0xB4EB582b0055d9f8B8ad862292cA1b33dfE8215C, 100000000);
        token.mint(0xd6f13F05DBB959f8DAA6721a088906Fef4Ad093c, 500000000);
        token.mint(0x220Ea3406b1b9d72B6386EA29EfF73a230D5d51c, 700000000);
        token.mint(0x87969413c2388B23c2ac871a61702d1b2d67b9CB, 2000000000);
        token.pause(); // Unpause after ICO is over
    }

    // fallback function can be used to buy tokens or participate in pre-ico
    function () public payable {
        if (validPurchasePre()) {
            buyTokensPre(msg.sender);
        } else if (validPurchaseIco()) {
            buyTokensIco(msg.sender);
        } else {
            return;
        }
    }

    function releaseTokens() public {
        require(hasEndedIco());

        token.finishMinting();
        token.unpause();
    }

    function setBaseRate(uint256 _baseRate) public onlyOwner {
        require(hasEndedPre());
        require(now < startTimeIco);

        baseRate = _baseRate;
    }

    // used to claim tokens once preico ends
    function claimTokens() public {
        require(hasEndedPre());
        require(!claimedTokens[msg.sender]);

        uint256 tokensPerWei = tokenValue();
        uint256 userTokens = (contributions[msg.sender] * tokensPerWei);

        token.mint(msg.sender, userTokens);
        claimedTokens[msg.sender] = true;

        TokenClaimed(msg.sender, userTokens);
    }

    // function to get current rate for ICO purchases
    function getRateIco() public constant returns (uint256) {
        if (now - startTimeIco < 5 days) {
            return baseRate;
        } else if (now - startTimeIco < 10 days) {
            return baseRate * 100 / 110;
        } else if (now - startTimeIco < 15 days) {
            return baseRate * 100 / 120;
        } else if (now - startTimeIco < 20 days) {
            return baseRate * 100 / 130;
        } else if (now - startTimeIco < 25 days) {
            return baseRate * 100 / 140;
        } else if (now - startTimeIco < 30 days) {
            return baseRate * 100 / 160;
        } else {
            return 0;
        }
    }

      // function gets the equivalent rate after bonuses for Pre-ICO
    function getRatePre() public constant returns (uint256) {
        if (now - startTimePre < 2 days) {
            return 200;
        } else if (now - startTimePre < 4 days) {
            return 190;
        } else if (now - startTimePre < 6 days) {
            return 180;
        } else if (now - startTimePre < 8 days) {
            return 170;
        } else if (now - startTimePre < 10 days) {
            return 160;
        } else if (now - startTimePre < 12 days) {
            return 150;
        } else {
            return 0;
        }
    }  

    // low level token purchase function
    function buyTokensIco(address _beneficiary) internal {
        require(_beneficiary != 0x0);

        // calculate token amount to be created
        uint256 weiAmount = msg.value;
        uint256 rate = getRateIco();
        uint256 tokens = weiAmount.mul(rate);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        tokensIssuedIco = tokensIssuedIco.add(tokens);
        token.mint(_beneficiary, tokens);

        // check the cap is respected
        require(tokensIssuedIco <= TOTAL_TOKENS_ICO);

        // issue events
        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        //forward eth
        forwardFunds();
    }

    function buyTokensPre(address _beneficiary) internal {
        require(_beneficiary != 0x0);

        // calculate contribution
        uint256 weiAmount = msg.value;
        uint256 rate = getRatePre();
        uint256 effectiveAmount = (weiAmount * rate) / 100;

        // update state
        weiRaised = weiRaised.add(weiAmount);
        contributions[_beneficiary] = contributions[_beneficiary] + effectiveAmount;
        totalContributions = totalContributions.add(effectiveAmount);

        // issue events
        WeiContributed(msg.sender, _beneficiary, weiAmount, effectiveAmount);

        // forward eth
        forwardFunds();
    }

    // Get the calculated value of a token for Pre-ICO
    function tokenValue() internal constant returns (uint256 tokensPerWei) {
        tokensPerWei = TOTAL_TOKENS_PRE / totalContributions;
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens from ICO
    function validPurchaseIco() internal constant returns (bool) {
        bool withinPeriod = now >= startTimeIco && now <= endTimeIco;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    // @return true if the transaction can buy tokens from Pre-ICO
    function validPurchasePre() internal constant returns (bool) {
        bool withinPeriod = now >= startTimePre && now <= endTimePre;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    // @return true if ICO event has ended
    function hasEndedIco() internal constant returns (bool) {
        return now > endTimeIco;
    }

    // @return true if Pre-ICO event has ended
    function hasEndedPre() internal constant returns (bool) {
        return now > endTimePre;
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    function createTokenContract() internal returns (Token) {
        return new Token();
    }

}
