// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";


/* 
    CT Token
    - Total Supply = Unlimited
    - Burnable
    - Mintable
    - Transfer Permit
    - Ownable
*/

contract CT_ERC20 is ERC20, ERC20Permit, ERC20Burnable, Ownable {
    // Events to be emited into blockchain for transparency
    event tokens_minted(address indexed receiver, uint256 amount);
    event tokens_transferred(address indexed receiver, uint256 amount);
    event tokens_permitted(address indexed receiver, uint256 amount);
    event beneficialAmount_updated(address indexed holder, uint256 amount);

    event withdrawalUser(address indexed holder, uint256 amount);
    event withdrawalOwner(address indexed owner, uint256 amount);

    // Token value && withdrawal tax
    uint256 public token_value = 0.01 ether;
    uint256 public withdrawal_tax = 10; // 10% tax

    mapping(address => uint256) public holder_benificialamount;
    uint256 public total_benificialamount;

    constructor(address initialOwner) ERC20("Carousell Token", "CT") ERC20Permit("Carousell Token") Ownable(initialOwner) {}

    function mint_token(address receiver, uint256 amount) external payable {
        require(msg.value >= (amount / (10**18)) * token_value);

        if(balanceOf(address(this)) >= amount) {
            _transfer(address(this), receiver, amount); // Tokens circulation
            emit tokens_transferred(receiver, amount);
        }
        else {
            _mint(receiver, amount);
            emit tokens_minted(receiver, amount);
        }
        uint256 final_benificialAmount = msg.value - (msg.value / withdrawal_tax);
        holder_benificialamount[receiver] += final_benificialAmount;
        total_benificialamount += msg.value;
        
        emit beneficialAmount_updated(receiver, final_benificialAmount);
    }

    function transfer_token(address from, address receiver, uint256 amount) external {
        uint256 updated_beneficialAmount = holder_benificialamount[from] * amount / balanceOf(from);
        _transfer(from, receiver, amount);

        holder_benificialamount[receiver] += updated_beneficialAmount;
        holder_benificialamount[from] -= updated_beneficialAmount;

        emit tokens_transferred(receiver, amount);
    }

    function withdraw() external {
        require(address(this).balance > 0);
        uint256 to_withdraw = holder_benificialamount[msg.sender];

        require(holder_benificialamount[msg.sender] > 0, "You currently have no tokens to withdraw.");
        payable(msg.sender).transfer(to_withdraw);
        
        transfer(address(this), balanceOf(msg.sender)); // can implement with custom value

        holder_benificialamount[msg.sender] -= to_withdraw; // can implement with custom amount
        total_benificialamount -= to_withdraw;

        emit withdrawalUser(msg.sender, to_withdraw);
    }

    // super
    function _withdraw() external onlyOwner {
        require(address(this).balance > 0, "ERC20 contract has no funds");
        uint256 to_withdraw = total_benificialamount;

        payable(owner()).transfer(to_withdraw);

        total_benificialamount -= to_withdraw;
        emit withdrawalOwner(owner(), to_withdraw);
    }

    // update token value with ERC4626 implementation
    // function update_token_value(uint256 new_token_value) internal onlyOwner { token_value = new_token_value; }

    // ERC20 permit
    function permit_token(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyOwner {
        _mint(owner, value);
        permit(owner, spender, value, deadline, v, r, s);
        approve(owner, value);
        transferFrom(owner, spender, value);

        emit tokens_permitted(spender, value);
    }

    // uncomment if needed
    // function burn_ct() internal onlyOwner {
    //     uint256 value = 100000 * 10**18;

    //     require(totalSupply() >= value);
    //     _burn(address(this), value);
    // }
}