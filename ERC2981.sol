// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

abstract contract ERC2981 {
  struct RoyaltyInfo {
    address recipient;
    uint96 amount;
  }

  mapping(uint256 => RoyaltyInfo) internal _royalties;

  function _setTokenRoyalty(
    uint256 tokenId,
    address recipient,
    uint96 value
  ) internal {
    require(value <= 10000, "ERC2981 : Too high");
    _royalties[tokenId] = RoyaltyInfo(recipient, value);
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (address, uint256)
  {
    RoyaltyInfo storage royalties = _royalties[tokenId];
    uint256 royaltyAmount = (salePrice * royalties.amount) / 10000;

    return (royalties.recipient, royaltyAmount);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    returns (bool)
  {
    return interfaceId == type(IERC2981).interfaceId;
  }
}
