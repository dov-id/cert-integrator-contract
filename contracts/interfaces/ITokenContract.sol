// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./ITokenFactory.sol";

/**
 * This is a TokenContract, which is an ERC721 token.
 * This contract allows users to buy NFT tokens for any ERC20 token and native currency, provided the admin signs off on the necessary data.
 * System admins can update the parameters
 * All funds for which users buy tokens can be withdrawn by the main owner of the system.
 */
interface ITokenContract {
    /*
     * @notice The structure that stores TokenContract init params
     * @param tokenName the name of the collection (Uses in ERC721 and ERC712)
     * @param tokenSymbol the symbol of the collection (Uses in ERC721)
     * @param tokenFactoryAddr the address of the TokenFactory contract
     */
    struct TokenContractInitParams {
        string tokenName;
        string tokenSymbol;
        address tokenFactoryAddr;
        address admin;
    }

    /*
     * @notice This event is emitted when the user has successfully minted a new token
     * @param recipient the address of the user who received the token and who paid for it
     * @param mintedTokenInfo the MintedTokenInfo struct with information about minted token
     * @param paymentTokenAddress the address of the payment token contract
     * @param paidTokensAmount the amount of tokens paid
     * @param paymentTokenPrice the price in USD of the payment token
     * @param discount discount value applied
     */
    event SuccessfullyMinted(address indexed recipient, uint256 tokenId, string tokenURI);

    /*
     * @notice The function for initializing contract variables
     * @param initParams_ the TokenContractInitParams structure with init params
     */
    function __TokenContract_init(TokenContractInitParams calldata initParams_) external;

    /*
     * @param tokenURI_ the tokenURI string
     */
    function mintToken(address to, string memory tokenURI_) external returns (uint256);

    /*
     * @notice The function that returns the address of the token factory
     * @return token factory address
     */
    function tokenFactory() external view returns (ITokenFactory);

    /*
     * @notice The function to check if there is a token with the passed token URI
     * @param tokenURI_ the token URI string to check
     * @return true if passed token URI exists, false otherwise
     */
    function existingTokenURIs(string memory tokenURI_) external view returns (bool);

    /*
     * @notice The function to get an array of tokenIDs owned by a particular user
     * @param userAddr_ the address of the user for whom you want to get information
     * @return tokenIDs_ the array of token IDs owned by the user
     */
    function getUserTokenIDs(address userAddr_) external view returns (uint256[] memory tokenIDs_);
}
