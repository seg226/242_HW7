// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts@4.9.3/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.9.3/security/ReentrancyGuard.sol";

/** 
 * @title Exchange
 * @dev Implements decentralized exchange automated market maker
 */
contract Exchange is ReentrancyGuard {

    ERC20 public token;

    uint tokenReserve;
    uint ethReserve;
    uint K;

    mapping(address => uint) liquidityPositions;
    uint totalLiquidityPositions;

    event LiquidityProvided(uint amountERC20TokenDeposited, uint amountEthDeposited, uint liquidityPositionsIssued);
    event LiquidityWithdrew(uint amountERC20TokenWithdrew, uint amountEthWithdrew, uint liquidityPositionsBurned);
    event SwapForEth(uint amountERC20TokenDeposited, uint amountEthWithdrew);
    event SwapForERC20Token(uint amountERC20TokenWithdrew, uint amountEthDeposited);

    constructor (address _token) {
        token = ERC20(_token);
    }

    function provideLiquidity(uint _amountERC20Token) external payable returns (uint issuedLiquidityPositions) {
        require(msg.value > 0, "Amount of ETH provided must be greater than zero");
        require(_amountERC20Token > 0, "Amount of ERC20 token provided must be greater than zero");
        
        if (totalLiquidityPositions == 0) {
            issuedLiquidityPositions = 100;
            //liquidityPositions[msg.sender] = issuedLiquidityPositions;
            //totalLiquidityPositions = issuedLiquidityPositions;
        } else {
            require(_amountERC20Token * ethReserve == msg.value * tokenReserve, "Eth and ERC20 tokens must be provided in ratio equal to the current ratio of tokens in the contract");

            issuedLiquidityPositions = totalLiquidityPositions * _amountERC20Token / tokenReserve;
            //liquidityPositions[msg.sender] += issuedLiquidityPositions;
            //totalLiquidityPositions += issuedLiquidityPositions;
        }

        token.transferFrom(msg.sender, address(this), _amountERC20Token);

        liquidityPositions[msg.sender] += issuedLiquidityPositions;
        totalLiquidityPositions += issuedLiquidityPositions;
       
        tokenReserve += _amountERC20Token;
        ethReserve += msg.value;
        K = tokenReserve * ethReserve;
        emit LiquidityProvided(_amountERC20Token, msg.value, issuedLiquidityPositions);
    }

    function estimateEthToProvide(uint _amountERC20Token) external view returns (uint amountEth) {
        amountEth = ethReserve * _amountERC20Token / tokenReserve;
    }

    function estimateERC20TokenToProvide(uint _amountEth) external view returns (uint amountERC20) {
        amountERC20 = tokenReserve * _amountEth / ethReserve;
    }

    function getMyLiquidityPositions() external view returns (uint userLiquidityPositions) {
        userLiquidityPositions = liquidityPositions[msg.sender];
    }

    function withdrawLiquidity(uint _liquidityPositionsToBurn) external nonReentrant returns (uint amountEthToSend, uint amountERC20ToSend) {
        // Caller shouldn’t be able to give up more liquidity positions than they own
        require(_liquidityPositionsToBurn > liquidityPositions[msg.sender], "You can not give up more liquidity positions than you own");
        // Caller shouldn’t be able to give up all the liquidity positions in the pool
        require(_liquidityPositionsToBurn > totalLiquidityPositions, "You can not give up all the liquidity positions in the pool");

        amountEthToSend = _liquidityPositionsToBurn * ethReserve / totalLiquidityPositions;
        amountERC20ToSend = _liquidityPositionsToBurn * tokenReserve / totalLiquidityPositions;

        // Decrement the caller’s liquidity positions and the total liquidity positions
        liquidityPositions[msg.sender] -= _liquidityPositionsToBurn;
        totalLiquidityPositions -= _liquidityPositionsToBurn;

        // Transfer Ether and ERC-20 from contract to caller
        token.transfer(msg.sender, amountERC20ToSend);
        payable(msg.sender).transfer(amountEthToSend);

        tokenReserve -= amountERC20ToSend;
        ethReserve -= amountEthToSend;
        
        // Update K: K = newContractEthBalance * newContractERC20TokenBalance
        K = tokenReserve * ethReserve;

        emit LiquidityWithdrew(amountERC20ToSend, amountEthToSend, _liquidityPositionsToBurn);
    }

    function swapForEth(uint _amountERC20Token) external nonReentrant returns (uint ethToSend) {
        require(_amountERC20Token > 0, "ERC20 sent must be greater than 0");
        uint contractERC20TokenBalanceAfterSwap = tokenReserve - _amountERC20Token;
        uint contractEthBalanceAfterSwap = K / contractERC20TokenBalanceAfterSwap;
        ethToSend = ethReserve - contractEthBalanceAfterSwap;

        // Transfer ERC-20 tokens from caller to contract
        token.transferFrom(msg.sender, address(this), _amountERC20Token);
        // Transfer Ether from contract to caller
        payable(msg.sender).transfer(ethToSend);

        tokenReserve += _amountERC20Token;
        ethReserve -= ethToSend;
        
        emit SwapForEth(_amountERC20Token, ethToSend);
    }

    function estimateSwapForEth(uint _amountERC20Token) external view returns (uint ethToSend){
        uint contractERC20TokenBalanceAfterSwap = tokenReserve - _amountERC20Token;
        uint contractEthBalanceAfterSwap = K / contractERC20TokenBalanceAfterSwap;
        ethToSend = ethReserve - contractEthBalanceAfterSwap;
    }

    function swapForERC20Token() external payable nonReentrant returns (uint ERC20TokenToSend) {
        require(msg.value > 0, "eth sent must be greater than 0");
        uint contractEthBalanceAfterSwap = ethReserve - msg.value;
        uint contractERC20TokenBalanceAfterSwap = K / contractEthBalanceAfterSwap;
        ERC20TokenToSend = tokenReserve - contractERC20TokenBalanceAfterSwap;

        // Transfer Ether from caller to contract (happens implicitly)
        // Transfer ERC-20 tokens from contract to caller
        token.transfer(msg.sender, ERC20TokenToSend);

        ethReserve += msg.value;
        tokenReserve -= ERC20TokenToSend;

        emit SwapForERC20Token(ERC20TokenToSend, msg.value);
    }

    function estimateSwapForERC20Token(uint _amountEth) external view returns (uint ERC20TokenToSend) {
        require(_amountEth > 0, "eth sent must be greater than 0");
        uint contractEthBalanceAfterSwap = ethReserve - _amountEth;
        uint contractERC20TokenBalanceAfterSwap = K / contractEthBalanceAfterSwap;
        ERC20TokenToSend = tokenReserve - contractERC20TokenBalanceAfterSwap;
    }
}