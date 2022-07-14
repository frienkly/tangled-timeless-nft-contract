// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ITWToken is IERC721Enumerable {
  enum TWClass {
    LUXURY,
    HIGHEND,
    ZENITH,
    MAX
  } // unint8

  struct mintInfo {
    uint256 tokenId;
    TWClass class;
    uint64 exchangeFee;
    uint128 exchangeTermSec;
    uint128 pointLimit;
  }

  struct TWInfo {
    bool isWearing;
    TWClass class;
    uint64 exchangeFee;
    uint128 exchangeTermSec;
    uint128 pointLimit;
    uint128 remainedExchangeSec;
    uint256 expectedExchangeTime;
    uint256 nextMixTime;
  }

  event SetLaunchPad(address indexed prev, address indexed to);
  event SetMaxLaunchPadSupply(uint256 indexed prev, uint256 indexed to);
  event SetFeeAddress(address indexed prev, address indexed to);
  event MakeWatch(address indexed userAddress, uint256 indexed tokenId);

  function getWatchInfo(uint256 tokenId) external view returns (TWInfo memory);

  function setWatchInfo(uint256 tokenId, TWInfo calldata info) external;

  function makeWatch(
    address userAddr,
    string calldata tokenUri,
    mintInfo calldata info
  ) external;

  function exists(uint256 tokenId) external view returns (bool);
}
