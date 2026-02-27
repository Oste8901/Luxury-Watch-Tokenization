// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IReceiverTemplate} from "./IReceiverTemplate.sol";
import {LuxuryWatch} from "./LuxuryWatch.sol";

/**
 * @title WatchMintingConsumer
 * @notice Consumer contract that receives CRE workflow reports and registers/mints luxury watches.
 * @dev Inherits IReceiverTemplate for secure DON-signed report validation.
 *
 * Flow:
 * 1. Off-chain watch data (brand, model, serial, appraisal) is sent to the CRE workflow via HTTP trigger.
 * 2. CRE workflow validates the data (dummy appraisal check) and generates a DON-signed report.
 * 3. The Forwarder validates signatures and calls this contract's onReport().
 * 4. This contract decodes the report and calls LuxuryWatch.registerAndMintWatch().
 */
contract WatchMintingConsumer is IReceiverTemplate {
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
    ) IReceiverTemplate(_expectedAuthor, _expectedWorkflowName) {
        luxuryWatch = LuxuryWatch(_luxuryWatch);
    }

    /**
     * @notice Receive report from the CRE Forwarder.
     * @param metadata Encoded metadata (not used in testing version)
     * @param report Encoded watch registration data
     */
    function onReport(bytes calldata metadata, bytes calldata report) external override {
        // In production, validate metadata here (workflow name, author, etc.)
        // For testing/demo purposes, we skip validation
        _processReport(report);
    }

    /**
     * @notice Process the watch registration report.
     * @param report ABI-encoded: (uint256 fractions, string brand, string model, string serial, uint256 pricePerFraction)
     */
    function _processReport(bytes calldata report) internal override {
        // Decode the report
        (
            uint256 fractions,
            string memory brand,
            string memory model,
            string memory serial,
            uint256 pricePerFraction
        ) = abi.decode(report, (uint256, string, string, string, uint256));

        // Get the current token ID before minting (will be the new watch's ID)
        uint256 watchId = luxuryWatch.tok_id();

        // Register and mint the watch
        // Note: The tokens are minted to this contract (msg.sender inside LuxuryWatch)
        // The owner can then transfer them as needed
        try luxuryWatch.registerAndMintWatch(fractions, brand, model, serial, pricePerFraction) {
            emit WatchRegistered(address(this), watchId, brand, model, fractions, pricePerFraction);
        } catch {
            revert RegistrationFailed();
        }
    }
} 
