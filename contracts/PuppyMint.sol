// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * puppymint semi-fungible token very wow
 *
 * allows users to wrap their PUP erc20 tokens into erc1155 sfts of specific denominations
 *
 * anybody can mint a coin by storing PUP erc20 in this contract
 * anybody can redeem a coin for its ascribed PUP erc20 value at any time
 */
contract PuppyMint is ERC1155, Ownable {
    string public name = "PuppyCoin";
    string public symbol = "PUP";
    string private _metadataURI = "https://assets.puppycoin.fun/metadata/{id}.json";
    string private _contractUri = "https://assets.puppycoin.fun/metadata/contract.json";

    IPuppyCoin puppyCoinContract = IPuppyCoin(_pupErc20Address());
    uint private MILLI_PUP_PER_PUP = 1000; // PUP erc20 has 3 decimals

    mapping(uint => uint) public valuePupByTokenId;
    uint public nextAvailableTokenId = 1;
    bool public baseUriFrozen = false;

    constructor() public ERC1155(_metadataURI) {}

    /**
     * gets the contract address for the PUP erc20 token.
     */
    function _pupErc20Address() internal view returns(address) {
        address addr;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                addr := 0x2696Fc1896F2D5F3DEAA2D91338B1D2E5f4E1D44
            }
            case 4 {
                // rinkeby
                addr := 0x183B665119F1289dFD446a2ebA29f858eE0D3224
            }
        }
        return addr;
    }

    /**
     * mint one or more puppymint sfts of the provided id
     *
     * sender must have first called approve() on the PUP token contract w/ this contract's address
     * for greater than or equal to the token id's pup value times numToMint
     */
    function mint(uint tokenId, uint numToMint) public {
        // the contract owner must have set this tokenId
        uint tokenValuePup = valuePupByTokenId[tokenId];
        require(tokenValuePup > 0, "illegal tokenId");

        // transfer PUP from the sender to this contract
        uint256 totalCostMilliPup = tokenValuePup * MILLI_PUP_PER_PUP * numToMint;
        puppyCoinContract.transferFrom(
            msg.sender,
            address(this),
            totalCostMilliPup
        );

        // mint one (or more) sfts, using denominationPup as the tokenId
        _mint(msg.sender, tokenId, numToMint, "");
    }

    /**
     * redeem one (or more) sfts for PUP
     */
    function redeem(uint tokenId, uint numToRedeem) public {
        // burn the sft(s)
        _burn(msg.sender, tokenId, numToRedeem);

        // send PUP to the caller
        uint tokenValuePup = valuePupByTokenId[tokenId];
        require(tokenValuePup > 0, "illegal token");
        uint milliPupToSend = tokenValuePup * MILLI_PUP_PER_PUP * numToRedeem;
        puppyCoinContract.transfer(
            msg.sender,
            milliPupToSend
        );
    }

    function contractURI() public view returns (string memory) {
      return _contractUri;
    }

    /**
     * creates a new token type with the provided value in PUP. 
     */
    function createNewToken(uint tokenValuePup)
        public
        onlyOwner
    {
        require(tokenValuePup > 0, "tokenValuePup cannot be 0");
        valuePupByTokenId[nextAvailableTokenId] = tokenValuePup;
        nextAvailableTokenId = nextAvailableTokenId + 1;
    }

    function setContractUri(string calldata newUri) public onlyOwner {
      _contractUri = newUri;
    }

    function setBaseUri(string calldata newUri) public onlyOwner {
        require(!baseUriFrozen, "base uri is frozen");
        _setURI(newUri);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return OpenSeaGasFreeListing.isApprovedForAll(owner, operator) || super.isApprovedForAll(owner, operator);
    }

    /**
     * DANGER BETCH! only call this if you're sure the current URI is good forever
     */
    function freezeBaseUri() public onlyOwner {
        baseUriFrozen = true;
    }
}

/**
 * very wow interface for the PUP erc-20 token
 */
interface IPuppyCoin {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function transfer(
        address recipient,
        uint256 amount
    ) external;
}

/**
 * much trust allow gas-free listing on opensea
 */
library OpenSeaGasFreeListing {
    function isApprovedForAll(address owner, address operator) internal view returns (bool) {
        ProxyRegistry registry;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
        }

        return address(registry) != address(0) && address(registry.proxies(owner)) == operator;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}