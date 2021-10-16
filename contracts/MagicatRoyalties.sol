// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./interfaces/IUniswapV2Pair.sol";
import './interfaces/IWFTM.sol';

contract MagicatRoyalties is Ownable {
    using SafeERC20 for IERC20;

    address public immutable xboo = address(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598);
    uint public devCut = 5000; // can be changed with a max of 50% (5000/10000)
    IUniswapV2Pair public immutable pair = IUniswapV2Pair(0xEc7178F4C41f346b2721907F5cF7628E388A7a58); // boo-ftm pair
    IERC20 public immutable boo = IERC20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE);
    address public immutable wftm = address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    address public devAddr;

    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "BrewBoo: must use EOA");
        _;
    }

    constructor (address _devAddr) {
        devAddr = _devAddr;
    }

    function distribute() public onlyEOA{
        _distribute();
    }

    receive() external payable {
        _distribute();
    }

    // internal functions

    function _distribute() internal {   
        uint ftmBal = address(this).balance;

        if (ftmBal > 0) {
            IWFTM(wftm).deposit{value: ftmBal}();
        }

        uint wftmBal = IERC20(wftm).balanceOf(address(this));

        require(wftmBal > 0, "_distribute, no FTM or wFTM balance");

        // send dev cut as native ftm
        IWFTM(wftm).withdraw(wftmBal * devCut / 10000);
        safeTransferFTM(devAddr, address(this).balance);

        wftmBal = IERC20(wftm).balanceOf(address(this));

        _swap(wftm, wftmBal, xboo);
    }

    function _swap(
        address fromToken,
        uint256 amountIn,
        address to
    ) internal returns (uint256 amountOut) {

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = fromToken == pair.token0() ? (reserve0, reserve1) : (reserve1, reserve0);
        IERC20(fromToken).safeTransfer(address(pair), amountIn);
        uint amountInput = IERC20(fromToken).balanceOf(address(pair)) - reserveInput; // calculate amount that was transferred, this accounts for transfer taxes

        amountOut = getAmountOut(amountInput, reserveInput, reserveOutput);
        (uint amount0Out, uint amount1Out) = fromToken == pair.token0() ? (uint(0), amountOut) : (amountOut, uint(0));
        pair.swap(amount0Out, amount1Out, to, new bytes(0));        
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'BrewBoo: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'BrewBoo: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 998;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function safeTransferFTM(address to, uint value) private {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: FTM_TRANSFER_FAILED');
    }

    // Admin Function

    function setDevAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "setDevAddr, address cannot be zero address");
        devAddr = _addr;
    }

    function setDevCut(uint _amount) external onlyOwner {
        require(_amount < 5000, "setDevCut: cut too high"); // max of 50%
        devCut = _amount;
    }


}