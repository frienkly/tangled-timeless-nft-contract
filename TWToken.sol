// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./ERC2981.sol";
import "./Interface/ITWToken.sol";

contract TWToken is
  ERC2981,
  ERC721URIStorage,
  ERC721Enumerable,
  ERC721Holder,
  AccessControl,
  Ownable,
  ITWToken
{
  bytes32 public constant TWTOKEN_ROLE = keccak256("TWTOKEN_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant TWINFO_EDIT_ROLE = keccak256("TWINFO_EDIT_ROLE");

  address public feeAddress;

  mapping(uint256 => TWInfo) private _twInfos;
  mapping(uint8 => uint96) public royaltyValue;

  // Galler related
  uint256 private _maxLaunchpadSupply;
  uint256 private _launchpadSupplied;
  address public launchPad;

  event SetFeeAddress(address indexed prev, address indexed to);

  constructor(
    address feeAddr,
    uint256 maxLaunchpad,
    address launchPadAddr
  ) ERC721("TangledWatch", "TW") Ownable() {
    feeAddress = feeAddr;

    _maxLaunchpadSupply = maxLaunchpad;
    launchPad = launchPadAddr;

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    royaltyValue[0] = 20;
    royaltyValue[1] = 30;
    royaltyValue[2] = 50;
  }

  modifier onlyLaunchpad() {
    require(launchPad != address(0), "LaunchPad should not be ZERO");
    require(msg.sender == launchPad, "Must call by launchPad");
    _;
  }

  function contractURI() public pure returns (string memory) {
    return "https://tangled.im/watch-metadata";
  }

  function getWatchInfo(uint256 tokenId) external view returns (TWInfo memory) {
    return _twInfos[tokenId];
  }

  function setFeeAddress(address addr) external onlyRole(TWTOKEN_ROLE) {
    require(addr != address(0), "Fee address shold not be ZERO adress");
    address prev = feeAddress;
    feeAddress = addr;

    emit SetFeeAddress(prev, feeAddress);
  }

  function setLaunchPad(address addr) external onlyRole(TWTOKEN_ROLE) {
    require(addr != address(0), "LaunchPad address shold not be ZERO adress");
    address prev = launchPad;
    launchPad = addr;

    emit SetLaunchPad(prev, addr);
  }

  function setWatchInfo(uint256 tokenId, TWInfo calldata info)
    external
    onlyRole(TWINFO_EDIT_ROLE)
  {
    _twInfos[tokenId] = info;
  }

  function setRoyaltyValue(uint8 twClass, uint96 val)
    external
    onlyRole(TWTOKEN_ROLE)
  {
    royaltyValue[twClass] = val;
  }

  function makeWatch(
    address userAddr,
    string calldata tokenUri,
    mintInfo calldata info
  ) external onlyRole(MINTER_ROLE) {
    _twInfos[info.tokenId] = TWInfo({
      isWearing: false,
      class: info.class,
      exchangeFee: info.exchangeFee,
      exchangeTermSec: info.exchangeTermSec,
      storageAmount: info.storageAmount,
      remainedExchangeSec: 0,
      expectedExchangeTime: 0,
      nextMixTime: info.class < TWClass.ZENITH ? block.timestamp : 0
    });

    _setTokenRoyalty(info.tokenId, feeAddress, royaltyValue[uint8(info.class)]);

    _safeMint(userAddr, info.tokenId);
    _setTokenURI(info.tokenId, tokenUri);

    emit MakeWatch(userAddr, info.tokenId);
  }

  function getOwnTokens(address addr) public view returns (uint256[] memory) {
    uint256 count = balanceOf(addr);
    uint256[] memory tokenIds = new uint256[](count);

    for (uint256 i = 0; i < count; ++i) {
      tokenIds[i] = tokenOfOwnerByIndex(addr, i);
    }

    return tokenIds;
  }

  // Galler adaptor
  function getMaxLaunchpadSupply() public view returns (uint256) {
    return _maxLaunchpadSupply;
  }

  function getLaunchpadSupply() public view returns (uint256) {
    return _launchpadSupplied;
  }

  function mintTo(address to, uint256 size) public onlyLaunchpad {
    require(to != address(0), "Can not mint to ZERO address");
    require(size > 0, "Size must greater than zero");
    require(
      _launchpadSupplied + size <= _maxLaunchpadSupply,
      "Max supply reached"
    );

    uint256[] memory twIds = getOwnTokens(address(this));
    require(twIds.length >= size, "Not enough prepared tokens");

    for (uint256 i = 0; i < size; ++i) {
      this.safeTransferFrom(address(this), to, twIds[i]);
    }
    _launchpadSupplied += size;
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return super._exists(tokenId);
  }

  function _burn(uint256 tokenId)
    internal
    virtual
    override(ERC721URIStorage, ERC721)
  {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721URIStorage, ERC721)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC2981, ERC721Enumerable, ERC721, IERC165, AccessControl)
    returns (bool)
  {
    return
      ERC2981.supportsInterface(interfaceId) ||
      super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721Enumerable, ERC721) {
    require(
      !_twInfos[tokenId].isWearing,
      "Cannot transfer wearing tangled watch"
    );

    super._beforeTokenTransfer(from, to, tokenId);
  }
}
