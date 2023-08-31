// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the Chainlink aggregator interface
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DynamicChainlinkFeed {
    // State variable to hold the current Chainlink feed address
    AggregatorV3Interface public priceFeed;

    // Event to log the latest price
    event LatestPrice(uint256 price, uint256 timestamp);

    // Function to set the Chainlink feed address dynamically
    function setPriceFeed(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // Function to get the latest price from the current Chainlink feed
    function getLatestPrice() public returns (uint256) {
        (
            uint80 roundID,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        emit LatestPrice(uint256(answer), updatedAt);

        return uint256(answer);
    }
}
