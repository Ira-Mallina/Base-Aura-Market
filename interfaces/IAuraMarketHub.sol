// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface IAuraMarketHub {
    function executePurchase(uint256 listingId) external payable;
    function cancelListing(uint256 listingId) external;
}
