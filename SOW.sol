// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SOW is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;
    uint256 public buyTaxPercentage = 1000;
    uint256 public sellTaxPercentage = 500;
    uint256 public maxWalletBalance = 30000 * 10**decimals();
    address public TreasuryWallet = 0x0000000000000000000000000000000000000000;
    address public LiquidityPair = 0x0000000000000000000000000000000000000000;
    mapping(address => bool) public isExcludedFromTax;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 30000 * (10**decimals()));
        isExcludedFromTax[msg.sender] = true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override 
    {
        // Check whale limit
        if (isExcludedFromTax[recipient]) {
            require(balanceOf(recipient) + amount <= maxWalletBalance, "Recipient balance exceeds maximum allowed");
        }
        uint256 taxAmount = 0;

        // Apply buy or sell tax only if neither sender nor recipient is excluded from tax
        if (!isExcludedFromTax[sender] && !isExcludedFromTax[recipient])
        {
            if (sender == LiquidityPair) 
            {
                // This is a buy operation
                taxAmount = calculateBuyTax(amount);
            } else if (recipient == LiquidityPair) 
            {
                // This is a sell operation
                taxAmount = calculateSellTax(amount);
            }
        }

        uint256 netAmount = amount - taxAmount;
        super._transfer(sender, recipient, netAmount);

        if (taxAmount > 0) 
        {
            super._transfer(sender, TreasuryWallet, taxAmount);
        }
    }

    function calculateSellTax(uint256 amount) public view returns (uint256) {
        return amount.mul(sellTaxPercentage).div(10000);
    }

    function setExcludedFromTax(address account, bool excluded) external onlyOwner {
        isExcludedFromTax[account] = excluded;
    }

    function calculateBuyTax(uint256 amount) public view returns (uint256) {
        return amount.mul(buyTaxPercentage).div(10000);
    }

    function setBuyTaxPercentage(uint256 newBuyTaxPercentage) external onlyOwner {
        require(newBuyTaxPercentage<=2500);
        buyTaxPercentage = newBuyTaxPercentage;
    }

    function setSellTaxPercentage(uint256 newSellTaxPercentage) external onlyOwner {
        require(newBuyTaxPercentage<=2500);
        sellTaxPercentage = newSellTaxPercentage;
    }

    function setMaxWalletBalance(uint256 newMaxWalletBalance) external onlyOwner {
        maxWalletBalance = newMaxWalletBalance * (10 ** decimals());
    }

    function setTresauryWallet(address newTresauryWallet) external onlyOwner {
        TreasuryWallet = newTresauryWallet;
    }

    function setLiquidityPair(address _LiquidityPair) external onlyOwner {
        LiquidityPair = _LiquidityPair;
    }

}
