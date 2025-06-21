// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title PredictionMarket
 * @dev A decentralized prediction market allowing users to bet on binary outcomes
 */
contract PredictionMarket is ReentrancyGuard, Ownable, Pausable {
    
    // Market states
    enum MarketState { Active, Resolved, Cancelled }
    
    // Outcome options
    enum Outcome { Yes, No }
    
    // Market structure
    struct Market {
        uint256 id;
        string question;
        string description;
        uint256 endTime;
        uint256 resolutionTime;
        MarketState state;
        Outcome winningOutcome;
        uint256 totalYesShares;
        uint256 totalNoShares;
        uint256 totalStaked;
        address creator;
        bool resolved;
    }
    
    // User position structure
    struct Position {
        uint256 yesShares;
        uint256 noShares;
        uint256 totalStaked;
        bool claimed;
    }
    
    // Events
    event MarketCreated(
        uint256 indexed marketId,
        string question,
        address indexed creator,
        uint256 endTime
    );
    
    event BetPlaced(
        uint256 indexed marketId,
        address indexed user,
        Outcome outcome,
        uint256 amount,
        uint256 shares
    );
    
    event MarketResolved(
        uint256 indexed marketId,
        Outcome winningOutcome,
        address indexed resolver
    );
    
    event Claimed(
        uint256 indexed marketId,
        address indexed user,
        uint256 payout
    );
    
    event MarketCancelled(uint256 indexed marketId);
    
    // State variables
    mapping(uint256 => Market) public markets;
    mapping(uint256 => mapping(address => Position)) public positions;
    mapping(address => bool) public resolvers;
    
    uint256 public nextMarketId = 1;
    uint256 public constant MIN_BET = 0.01 ether;
    uint256 public constant MAX_BET = 10 ether;
    uint256 public constant RESOLUTION_PERIOD = 7 days;
    uint256 public protocolFee = 200; // 2% in basis points
    uint256 public constant MAX_PROTOCOL_FEE = 500; // 5% max
    
    modifier onlyResolver() {
        require(resolvers[msg.sender] || msg.sender == owner(), "Not authorized resolver");
        _;
    }
    
    modifier marketExists(uint256 marketId) {
        require(marketId < nextMarketId && marketId > 0, "Market does not exist");
        _;
    }
    
    modifier marketActive(uint256 marketId) {
        require(markets[marketId].state == MarketState.Active, "Market not active");
        require(block.timestamp < markets[marketId].endTime, "Market ended");
        _;
    }
    
    constructor() Ownable(msg.sender) {
        resolvers[msg.sender] = true;
    }
    
    /**
     * @dev Create a new prediction market
     * @param question The question to be resolved
     * @param description Additional details about the market
     * @param duration Duration in seconds until market ends
     */
    function createMarket(
        string memory question,
        string memory description,
        uint256 duration
    ) external whenNotPaused returns (uint256) {
        require(bytes(question).length > 0, "Question cannot be empty");
        require(duration >= 1 hours && duration <= 365 days, "Invalid duration");
        
        uint256 marketId = nextMarketId++;
        uint256 endTime = block.timestamp + duration;
        
        markets[marketId] = Market({
            id: marketId,
            question: question,
            description: description,
            endTime: endTime,
            resolutionTime: endTime + RESOLUTION_PERIOD,
            state: MarketState.Active,
            winningOutcome: Outcome.Yes, // Default, not used until resolved
            totalYesShares: 0,
            totalNoShares: 0,
            totalStaked: 0,
            creator: msg.sender,
            resolved: false
        });
        
        emit MarketCreated(marketId, question, msg.sender, endTime);
        return marketId;
    }
    
    /**
     * @dev Place a bet on a market outcome
     * @param marketId ID of the market
     * @param outcome The outcome to bet on (Yes or No)
     */
    function placeBet(
        uint256 marketId,
        Outcome outcome
    ) external payable nonReentrant whenNotPaused marketExists(marketId) marketActive(marketId) {
        require(msg.value >= MIN_BET && msg.value <= MAX_BET, "Invalid bet amount");
        
        Market storage market = markets[marketId];
        Position storage position = positions[marketId][msg.sender];
        
        // Calculate shares based on current odds
        uint256 shares = calculateShares(marketId, outcome, msg.value);
        require(shares > 0, "Invalid shares calculation");
        
        // Update market totals
        market.totalStaked += msg.value;
        
        if (outcome == Outcome.Yes) {
            market.totalYesShares += shares;
            position.yesShares += shares;
        } else {
            market.totalNoShares += shares;
            position.noShares += shares;
        }
        
        position.totalStaked += msg.value;
        
        emit BetPlaced(marketId, msg.sender, outcome, msg.value, shares);
    }
    
    /**
     * @dev Calculate shares based on current market state
     * @param marketId ID of the market
     * @param outcome The outcome being bet on
     * @param amount The bet amount
     * @return Number of shares
     */
    function calculateShares(
        uint256 marketId,
        Outcome outcome,
        uint256 amount
    ) public view marketExists(marketId) returns (uint256) {
        Market storage market = markets[marketId];
        
        if (market.totalYesShares == 0 && market.totalNoShares == 0) {
            // First bet, 1:1 ratio
            return amount;
        }
        
        uint256 totalShares = market.totalYesShares + market.totalNoShares;
        uint256 outcomeShares;
        
        if (outcome == Outcome.Yes) {
            outcomeShares = market.totalYesShares;
        } else {
            outcomeShares = market.totalNoShares;
        }
        
        // Simple automated market maker formula
        // Price = outcomeShares / totalShares
        uint256 price = (outcomeShares * 1e18) / totalShares;
        if (price == 0) price = 1e18 / 2; // 50% if no shares
        
        return (amount * 1e18) / price;
    }
    
    /**
     * @dev Resolve a market with the winning outcome
     * @param marketId ID of the market to resolve
     * @param winningOutcome The winning outcome
     */
    function resolveMarket(
        uint256 marketId,
        Outcome winningOutcome
    ) external onlyResolver marketExists(marketId) {
        Market storage market = markets[marketId];
        
        require(market.state == MarketState.Active, "Market not active");
        require(block.timestamp >= market.endTime, "Market still active");
        require(block.timestamp <= market.resolutionTime, "Resolution period expired");
        require(!market.resolved, "Market already resolved");
        
        market.state = MarketState.Resolved;
        market.winningOutcome = winningOutcome;
        market.resolved = true;
        
        emit MarketResolved(marketId, winningOutcome, msg.sender);
    }
    
    /**
     * @dev Claim winnings from a resolved market
     * @param marketId ID of the market
     */
    function claimWinnings(
        uint256 marketId
    ) external nonReentrant marketExists(marketId) {
        Market storage market = markets[marketId];
        Position storage position = positions[marketId][msg.sender];
        
        require(market.state == MarketState.Resolved, "Market not resolved");
        require(!position.claimed, "Already claimed");
        require(position.totalStaked > 0, "No position in market");
        
        uint256 payout = calculatePayout(marketId, msg.sender);
        require(payout > 0, "No winnings to claim");
        
        position.claimed = true;
        
        // Calculate protocol fee
        uint256 fee = (payout * protocolFee) / 10000;
        uint256 userPayout = payout - fee;
        
        // Transfer winnings
        (bool success, ) = payable(msg.sender).call{value: userPayout}("");
        require(success, "Transfer failed");
        
        emit Claimed(marketId, msg.sender, userPayout);
    }
    
    /**
     * @dev Calculate potential payout for a user
     * @param marketId ID of the market
     * @param user Address of the user
     * @return Potential payout amount
     */
    function calculatePayout(
        uint256 marketId,
        address user
    ) public view marketExists(marketId) returns (uint256) {
        Market storage market = markets[marketId];
        Position storage position = positions[marketId][user];
        
        if (market.state != MarketState.Resolved || position.claimed) {
            return 0;
        }
        
        uint256 winningShares;
        uint256 totalWinningShares;
        
        if (market.winningOutcome == Outcome.Yes) {
            winningShares = position.yesShares;
            totalWinningShares = market.totalYesShares;
        } else {
            winningShares = position.noShares;
            totalWinningShares = market.totalNoShares;
        }
        
        if (winningShares == 0 || totalWinningShares == 0) {
            return 0;
        }
        
        // Payout = (user_winning_shares / total_winning_shares) * total_staked
        return (winningShares * market.totalStaked) / totalWinningShares;
    }
    
    /**
     * @dev Cancel a market (emergency function)
     * @param marketId ID of the market to cancel
     */
    function cancelMarket(uint256 marketId) external onlyOwner marketExists(marketId) {
        Market storage market = markets[marketId];
        require(market.state == MarketState.Active, "Market not active");
        
        market.state = MarketState.Cancelled;
        emit MarketCancelled(marketId);
    }
    
    /**
     * @dev Claim refund from a cancelled market
     * @param marketId ID of the cancelled market
     */
    function claimRefund(uint256 marketId) external nonReentrant marketExists(marketId) {
        Market storage market = markets[marketId];
        Position storage position = positions[marketId][msg.sender];
        
        require(market.state == MarketState.Cancelled, "Market not cancelled");
        require(!position.claimed, "Already claimed");
        require(position.totalStaked > 0, "No stake to refund");
        
        uint256 refund = position.totalStaked;
        position.claimed = true;
        
        (bool success, ) = payable(msg.sender).call{value: refund}("");
        require(success, "Refund failed");
    }
    
    // Admin functions
    function addResolver(address resolver) external onlyOwner {
        resolvers[resolver] = true;
    }
    
    function removeResolver(address resolver) external onlyOwner {
        resolvers[resolver] = false;
    }
    
    function setProtocolFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_PROTOCOL_FEE, "Fee too high");
        protocolFee = newFee;
    }
    
    function withdrawProtocolFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // View functions
    function getMarket(uint256 marketId) external view marketExists(marketId) returns (Market memory) {
        return markets[marketId];
    }
    
    function getUserPosition(uint256 marketId, address user) external view marketExists(marketId) returns (Position memory) {
        return positions[marketId][user];
    }
    
    function getMarketOdds(uint256 marketId) external view marketExists(marketId) returns (uint256 yesOdds, uint256 noOdds) {
        Market storage market = markets[marketId];
        
        if (market.totalYesShares == 0 && market.totalNoShares == 0) {
            return (50, 50); // 50-50 odds for new market
        }
        
        uint256 totalShares = market.totalYesShares + market.totalNoShares;
        yesOdds = (market.totalYesShares * 100) / totalShares;
        noOdds = (market.totalNoShares * 100) / totalShares;
    }
}