
pragma solidity >=0.7.0 <0.9.0;
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


function provideLiquidity(uint256 _amountERC20Token) external payable returns (uint256 liquidity){
    require(_amountERC20Token > 0, "Must provide ERC20 tokens");
    require(msg.value > 0, "Must provide Ether");

    uint256 ethBalanceBefore = _getEthBalance() - msg.value;
    uint256 tokenBalanceBefore = _getTokenBalance();

    //if user is the first depositor, give them 100 liquidity 
    if(totalLiquidityPositions == 0){
        liquidity = 100;
        totalLiquidityPositions = liquidity;
        liquidityPositions[msg.sender] = liquidity;

        _recalculateK();

        //event logged 
        emit LiquidityProvided(_amountERC20Token, msg.value, liquidity);
        return liquidity;

    }

    //else if it is not the first liquidity provider:
    //CHECK ON THIS!
    //x*y=k 
    uint256 requiredEth = (ethBalanceBefore * _amountERC20Token) / tokenBalanceBefore;
    require(msg.value == requiredEth, "Not enough ETH for current ratio");

    //from instructions
    liquidity = (totalLiquidityPositions * _amountERC20Token) / tokenBalanceBefore;


    liquidityPositions[msg.sender] += liquidity;
    totalLiquidityPositions += liquidity;
    _recalculateK();

    //log event
    emit LiquidityProvided(_amountERC20Token, msg.value, liquidity);
    return liquidity;
}

//last four functions

function swapForEth(uint256 _amountERC20Token) external returns (uint256 ethSend){
    require (_amountERC20Token>0, "Token must be > 0");
    require (K>0, "funds empty");

    //transfer ERC-20 tokens from caller to contract

    

    //eth balance before, minus eth abalnce after which is equal to 
    //k /token balance adter which is the tokenbalance before + amountERCtoken
    require ((K/(token.balanceOf(address(this)) + _amountERC20Token) < address(this).balance), "No ETH available to send");
    ethSend = address(this).balance - (K/(token.balanceOf(address(this))+ _amountERC20Token));


     //transfer ERC-20 tokens from caller to contract
    require (token.transferFrom(msg.sender, address(this), _amountERC20Token), "ERC20 transfer failed");

    //transfer ether from contract to caller
    payable(msg.sender).transfer(ethSend);

    emit SwapForEth( _amountERC20Token, ethSend);
    return ethSend;


    //retunr the amount of ether sent
}


//these are the last three functions I am working through 

function estimateSwapForEth (uint _amountToken) external view returns (uint){
    require (_amountToken>0, "Token must be > 0");
    require (K>0, "funds empty");

    //the amount of eth that can be sent is the balance of the tokens plus whatever the amount passed into the function
    uint ethToSend = token.balanceOf(address(this)) + _amountToken;
    //we are utilizing the ratio to see how much eth exists after the token transaction
    uint ethAfter = K/ethToSend;
    //here we get the estimated amount of Eth we would get if we were swapping ERC20Tokens
    return address(this).balance - ethAfter;
}

function swapForERC20Token() external payable returns (uint){
   require (msg.value >0, "Send ETH");
   require (K>0, "funds empty");

   uint newEthBalance = address(this).balance;
   uint newToken= K/newEthBalance;
   uint tokensToSend = token.balanceOf(address(this))- newToken;

    token.transfer(msg.sender, tokensToSend);
    emit SwapForERC20Token (tokensToSend, msg.value);
    return tokensToSend;

}

function estimateSwapForERC20Token(uint _amountEth) external view returns (uint){
   //check to make sure there is eth to be swapped

   require (_amountEth>0, "Eth must be > 0");
   require (K>0, "funds empty");
   
   //here we are finding the new balance by comparing the amount left with the tokens you are looking to exchange
    uint newEthBalance = address(this).balance + _amountEth;
    //we are upholding the relationship between the tokens and eth here to determine how many are left
    uint tokenAfter = K / newEthBalance;
   //then returning the difference
    return token.balanceOf(address(this)) - tokenAfter;
}

}


