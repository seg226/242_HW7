// SPDX-License-Identifier: UNLICENSED
pragma solidity  >=0.8.2 <=0.8.19.0;
import "@openzeppelin/contracts@4.9.3/token/ERC20/ERC20.sol";
contract Exchange{

    //necessary variables

    ERC20 public token;
    //from instructions
    mapping (address => uint256) public liquidityPositions;

    //this is universal so it can continue to be updates
    uint256 public totalLiquidityPositions;

    //this is necessary to maintain the ratio
    uint256 public K;



    //Events that are necessary
    event LiquidityProvided (
        uint256 amountERC20TokenDeposited,
        uint256 amountEthDeposited,
        uint256 liquidityPositionsIssued
    );

    event LiquidityWithdrew(
        uint256 amountERC20TokenWithdrew,
        uint256 amountEthWithdrew,
        uint256 liquidityPositionsBurned
    );

    event SwapForEth(
        uint256 amountERCTokenWithdrew,
        uint256 amountEthDeposited

    );

    event SwapForERC20Token(
        uint256 amountERC20TokenWithdrew,
        uint256 amountEthDeposited
    );
    //constructor should accept an ERC-20 token address:contentRefernce
    constructor (address _tokenAddress){
        require (_tokenAddress != address(0), "Invalid token address");
        token = ERC20 (_tokenAddress);
    }

    function _getEthBalance() internal view returns (uint256){
        return address(this).balance;
    }

    function _getTokenBalance() internal view returns (uint256){
        return token.balanceOf(address(this));
    }

    function _recalculateK() internal {
        uint256 ethBal= _getEthBalance();
        uint256 tokenBal= _getTokenBalance();
        K = ethBal * tokenBal;
    }



    function getMyLiquidPositions() external view returns (uint256)
{
    return liquidityPositions[msg.sender];
}
    function estimateToProvide(uint _amountERC20Token) external view returns(uint){
        uint contractEthBalance = address(this).balance;
        uint contractERC20TokenBalance = token.balanceOf(address(this));
        require(contractERC20TokenBalance>0,"ERC20 token blanace needs to be >0");
        return contractEthBalance * _amountERC20Token / contractERC20TokenBalance;

    }
    function estimateERC20TokenToProvide(uint _amountEth) external view returns(uint){
        uint contractERC20TokenBalance = token.balanceOf(address(this));
        uint contractEthBalance = address(this).balance;
        require(contractEthBalance>0,"ETH needs to be >0");
        return contractERC20TokenBalance * _amountEth/contractEthBalance;
    }
}

