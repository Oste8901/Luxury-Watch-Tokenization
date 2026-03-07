// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IReceiverTemplate} from "./IReceiverTemplate.sol";
import {LuxuryWatch} from "./LuxuryWatch.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WatchMintingConsumer
 * @notice Consumer contract that receives CRE workflow reports and registers/mints luxury watches.
 * @dev Inherits IReceiverTemplate for secure DON-signed report validation.
 */
contract WatchMintingConsumer is IReceiverTemplate, ERC1155Holder, Ownable {
    LuxuryWatch public immutable luxuryWatch;

    event WatchRegistered(
        address indexed owner,
        uint256 indexed watchId,
        string brand,
        string model,
        uint256 fractions,
        uint256 pricePerFraction
    );

    error RegistrationFailed();

    /**
     * @notice Construct the watch minting consumer
     * @param _luxuryWatch Address of the LuxuryWatch ERC-1155 contract
     * @param _expectedAuthor Expected workflow owner address (use address(0) for testing)
     * @param _expectedWorkflowName Expected workflow name (use bytes10("dummy") for testing)
     */
    constructor(
        address _luxuryWatch,
        address _expectedAuthor,
        bytes10 _expectedWorkflowName
    ) IReceiverTemplate(_expectedAuthor, _expectedWorkflowName) Ownable(msg.sender) {
        luxuryWatch = LuxuryWatch(_luxuryWatch);
    }

    /**
     * @notice Receive report from the CRE Forwarder.
     */
    function onReport(bytes calldata metadata, bytes calldata report) external override {
        _processReport(report);
    }

    /**
     * @notice Process the watch registration report.
     */
    function _processReport(bytes calldata report) internal override {
        (
            uint256 fractions,
            string memory brand,
            string memory model,
            string memory serial,
            uint256 pricePerFraction
        ) = abi.decode(report, (uint256, string, string, string, uint256));

        uint256 watchId = luxuryWatch.tok_id();

        try luxuryWatch.registerAndMintWatch(fractions, brand, model, serial, pricePerFraction) {
            emit WatchRegistered(address(this), watchId, brand, model, fractions, pricePerFraction);
        } catch {
            revert RegistrationFailed();
        }
    }

    /**
     * @notice Proxy to update the sale status of a watch owned by this contract.
     */
    function updateWatchSaleStatus(uint256 watchId, bool forSale) external onlyOwner {
        luxuryWatch.UpdateChoice(watchId, forSale);
    }

    /**
     * @notice Proxy to update the fraction price of a watch owned by this contract.
     */
    function setWatchFractionPrice(uint256 watchId, uint256 newPrice) external onlyOwner {
        luxuryWatch.setFractionPrice(watchId, newPrice);
    }

    /**
     * @dev ERC165 interface support override for multiple inheritance.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IReceiverTemplate, ERC1155Holder) returns (bool) {
        return IReceiverTemplate.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }
}

