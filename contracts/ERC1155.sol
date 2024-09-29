// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";


contract CT_ERC1155 is ERC1155, Ownable, ERC1155Supply {
    string private _baseURI;
    mapping(uint256 => string) private _tokenURIs;

    constructor(address initialOwner, string memory initialURI, uint256[] memory tokenIDs, uint256[] memory initialSupply) ERC1155(initialURI) Ownable(initialOwner) {
        _baseURI = initialURI;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            _tokenURIs[tokenIDs[i]] = _baseURI;
        }
        if(tokenIDs.length == 1) {
            _mint(initialOwner, tokenIDs[0], initialSupply[0], "");
        }
        else {
            _mintBatch(initialOwner, tokenIDs, initialSupply, "");
        }
    }

    // update or setup new URI for existing or newly tokenID
    function setURI(uint256 tokenID, string memory newURI) public onlyOwner { 
        _tokenURIs[tokenID] = newURI;
        emit URI(newURI, tokenID);
    }

    // return intiial URI
    function getURI() public view returns(string memory) {
        return _baseURI;
    }

    // return token's uri (newly added)
    function uri(uint256 tokenID) override public view returns(string memory) {
        return(_tokenURIs[tokenID]);
    } 

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }

    // Override transferOwnership (if buyer decides to buy all the products at once)
    function transferOwnership(address newOwner) public override onlyOwner {
        address oldOwner = owner();
        super.transferOwnership(newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}