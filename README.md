Prediction Market
A decentralized prediction market smart contract built on Ethereum that allows users to create and bet on binary outcome events. The platform features an automated market maker (AMM) for price discovery and fair payouts.

🚀 Features
Core Functionality
Market Creation: Anyone can create binary (Yes/No) prediction markets
Decentralized Betting: Users can place bets on market outcomes using ETH
Automated Market Maker: Dynamic pricing based on current market positions
Fair Resolution: Authorized resolvers determine winning outcomes
Automated Payouts: Winners can claim rewards automatically
Security & Governance
Access Control: Owner and resolver role management
Emergency Controls: Market cancellation with full refunds
Reentrancy Protection: Secure against common attack vectors
Pausable Contract: Emergency pause functionality
Protocol Fees: Configurable fee structure (default 2%, max 5%)
User Experience
Real-time Odds: Dynamic odds calculation based on betting activity
Position Tracking: Individual user positions tracked per market
Gas Optimization: Efficient contract design for lower transaction costs
Time-based Markets: Markets with defined duration and resolution periods
📋 Contract Overview
Market States
Active: Market is open for betting
Resolved: Market outcome determined, winners can claim
Cancelled: Market cancelled, all participants get refunds
Key Parameters
Minimum Bet: 0.01 ETH
Maximum Bet: 10 ETH
Resolution Period: 7 days after market end
Default Protocol Fee: 2%
Maximum Protocol Fee: 5%
🛠 Installation & Setup
Prerequisites
Node.js v16 or higher
npm or yarn
Git
Clone Repository
bash
git clone https://github.com/yourusername/prediction-market.git
cd prediction-market
Install Dependencies
bash
npm install
Environment Setup
Create a .env file in the root directory:

env
PRIVATE_KEY=your_private_key_here
GOERLI_URL=https://goerli.infura.io/v3/your_infura_key
SEPOLIA_URL=https://sepolia.infura.io/v3/your_infura_key
MAINNET_URL=https://mainnet.infura.io/v3/your_infura_key
ETHERSCAN_API_KEY=your_etherscan_api_key
🚀 Deployment
Local Development
bash
# Start local Hardhat node
npx hardhat node

# Deploy to local network
npx hardhat run scripts/deploy.js --network localhost
Testnet Deployment
bash
# Deploy to Goerli testnet
npx hardhat run scripts/deploy.js --network goerli

# Deploy to Sepolia testnet
npx hardhat run scripts/deploy.js --network sepolia
Mainnet Deployment
bash
# Deploy to Ethereum mainnet
npx hardhat run scripts/deploy.js --network mainnet
🧪 Testing
Run All Tests
bash
npx hardhat test
Run Specific Test File
bash
npx hardhat test test/PredictionMarket.test.js
Test Coverage
bash
npx hardhat coverage
Gas Report
bash
REPORT_GAS=true npx hardhat test
📖 Usage Examples
Creating a Market
javascript
const tx = await predictionMarket.createMarket(
  "Will Bitcoin reach $100k by end of 2024?",
  "Market resolves based on CoinGecko price on Dec 31, 2024",
  86400 * 30 // 30 days duration
);
Placing a Bet
javascript
// Bet on "Yes" outcome
await predictionMarket.connect(user).placeBet(
  marketId, 
  0, // 0 = Yes, 1 = No
  { value: ethers.utils.parseEther("1.0") }
);
Resolving a Market
javascript
// Only authorized resolvers can call this
await predictionMarket.connect(resolver).resolveMarket(
  marketId,
  0 // 0 = Yes wins, 1 = No wins
);
Claiming Winnings
javascript
await predictionMarket.connect(winner).claimWinnings(marketId);
🏗 Contract Architecture
Main Contract: PredictionMarket.sol
Inherits from OpenZeppelin's ReentrancyGuard, Ownable, and Pausable
Manages market lifecycle from creation to resolution
Handles betting, payout calculations, and fee distribution
Key Data Structures
Market Structure
solidity
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
Position Structure
solidity
struct Position {
    uint256 yesShares;
    uint256 noShares;
    uint256 totalStaked;
    bool claimed;
}
🔧 API Reference
View Functions
getMarket(uint256 marketId) → Market
Returns complete market information.

getUserPosition(uint256 marketId, address user) → Position
Returns user's position in a specific market.

calculatePayout(uint256 marketId, address user) → uint256
Calculates potential payout for a user in a resolved market.

getMarketOdds(uint256 marketId) → (uint256 yesOdds, uint256 noOdds)
Returns current market odds as percentages.

calculateShares(uint256 marketId, Outcome outcome, uint256 amount) → uint256
Calculates shares received for a given bet amount.

State-Changing Functions
createMarket(string question, string description, uint256 duration) → uint256
Creates a new prediction market.

placeBet(uint256 marketId, Outcome outcome) payable
Places a bet on a market outcome.

resolveMarket(uint256 marketId, Outcome winningOutcome)
Resolves a market with the winning outcome (resolver only).

claimWinnings(uint256 marketId)
Claims winnings from a resolved market.

claimRefund(uint256 marketId)
Claims refund from a cancelled market.

Admin Functions
addResolver(address resolver)
Adds a new authorized resolver (owner only).

removeResolver(address resolver)
Removes an authorized resolver (owner only).

setProtocolFee(uint256 newFee)
Sets the protocol fee (owner only, max 5%).

cancelMarket(uint256 marketId)
Cancels a market for emergency situations (owner only).

pause() / unpause()
Pauses/unpauses the contract (owner only).

withdrawProtocolFees()
Withdraws accumulated protocol fees (owner only).

📊 Economics & Incentives
Automated Market Maker (AMM)
The contract uses a simple AMM formula for price discovery:

Price = outcome_shares / total_shares
Shares = bet_amount / price
Fee Structure
Protocol Fee: 2% of winnings (configurable, max 5%)
Gas Costs: Users pay standard Ethereum gas fees
No Trading Fees: No fees for placing bets
Payout Calculation
Payout = (user_winning_shares / total_winning_shares) × total_pool
Final_Payout = Payout - Protocol_Fee
🔒 Security Considerations
Implemented Protections
Reentrancy Guard: Prevents reentrancy attacks
Access Control: Role-based permissions for critical functions
Input Validation: Comprehensive parameter validation
Overflow Protection: Uses Solidity 0.8+ built-in overflow checks
Pausable: Emergency stop functionality
Best Practices
Time Locks: Markets have resolution periods to prevent rushed decisions
Multi-sig Recommended: Use multi-signature wallets for owner operations
Resolver Verification: Verify resolver addresses before adding them
Regular Audits: Recommend professional security audits before mainnet deployment
🤝 Contributing
Development Setup
Fork the repository
Create a feature branch: git checkout -b feature/amazing-feature
Make your changes and add tests
Ensure all tests pass: npm test
Commit your changes: git commit -m 'Add amazing feature'
Push to the branch: git push origin feature/amazing-feature
Open a Pull Request
Code Standards
Follow Solidity style guide
Add comprehensive tests for new features
Include NatSpec documentation for public functions
Maintain gas efficiency
Reporting Issues
Use GitHub Issues for bug reports
Include reproduction steps and expected behavior
Provide contract addresses for mainnet/testnet issues
📝 License
This project is licensed under the MIT License - see the LICENSE file for details.

🙏 Acknowledgments
OpenZeppelin: For secure, audited smart contract components
Hardhat: For excellent development and testing framework
Ethereum Community: For continuous innovation and support
📞 Support
Documentation: Check this README and inline code comments
Issues: GitHub Issues for bug reports and feature requests
Discussions: GitHub Discussions for general questions
Discord: Join our Discord server for real-time support
🗺 Roadmap
Phase 1 (Current)
 Core prediction market functionality
 Automated market maker
 Comprehensive test suite
 Deployment scripts
Phase 2 (Planned)
 Multi-outcome markets (beyond binary)
 ERC20 token support for betting
 Oracle integration for automatic resolution
 Frontend interface development
Phase 3 (Future)
 Layer 2 deployment (Polygon, Arbitrum)
 Governance token implementation
 Advanced AMM curves
 Market maker incentives
⚠️ Disclaimer: This smart contract is provided as-is for educational and development purposes. While extensively tested, it has not undergone a professional security audit. Use at your own risk and consider getting a security audit before deploying to mainnet with significant funds.

Screenshot : ![Screenshot (1)](https://github.com/user-attachments/assets/97adb108-b277-479d-979a-b77f996834c9)
Address: 0x7B612f55ea3E23B9EC2d6E093542649908D908D2
