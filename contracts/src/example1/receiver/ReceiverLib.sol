//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// This prob wont work
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library ReceiverLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("receiverlib.v1.storage");
    IPyth constant pyth = IPyth(address(0xff1a0f4744e8582DF1aE09D5611b887B6a12925C));


    struct DiamondStorage {
        uint256 latestTimestamp;
        int256 latestData;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // Switchboard Function will call this function with the feed ids and values
    function callback(
        address[] calldata chainlinkPriceIds,
        bytes32[] calldata pythPriceIds,
        bytes[] calldata pythVaas
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        // https://docs.pyth.network/documentation/pythnet-price-feeds/evm
        uint fee = pyth.getUpdateFee(pythVaas);
        pyth.updatePriceFeeds{ value: fee }(pythVaas);
        for (uint i = 0; i < pythPriceIds.length; i++) {
            PythStructs.Price memory pythPrice = pyth.getPrice(pythPriceIds[i]);
            AggregatorV3Interface clPriceFeed = AggregatorV3Interface(chainlinkPriceIds[i]);
            (
                /* uint80 roundID */,
                int chainlinkPrice,
                /*uint startedAt*/,
                /*uint timeStamp*/,
                /*uint80 answeredInRound*/
            ) = clPriceFeed.latestRoundData();
        }
    }

    function viewData() internal view returns (int256 data, uint256 timestamp) {
        DiamondStorage storage ds = diamondStorage();
    }
}
