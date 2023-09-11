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
        uint256 pythPrice;
        uint256 chainlinkPrice;
        uint256 switchboardPrice;
        uint256 answer;
        uint256 variance;
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
        uint256[] calldata switchboardPrices,
        address[] calldata chainlinkPriceIds,
        bytes32[] calldata pythPriceIds,
        bytes[] calldata pythVaas
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        // https://docs.pyth.network/documentation/pythnet-price-feeds/evm
        if (pythVaas.length != 0) {
            uint fee = pyth.getUpdateFee(pythVaas);
            pyth.updatePriceFeeds{ value: fee }(pythVaas);
        }
        PythStructs.Price memory pythPrice = pyth.getPrice(pythPriceIds[0]);
        AggregatorV3Interface clPriceFeed = AggregatorV3Interface(chainlinkPriceIds[0]);
        (, int chainlinkPrice, , , ) = clPriceFeed.latestRoundData();
        int256 pythResult = pythPrice.price;
        require(pythPrice.price >= 0, "Cannot convert a negative int64 to uint256");
        uint256[] memory prices = new uint256[](3);
        prices[0] = switchboardPrices[0];
        prices[1] = uint256(pythResult);
        prices[2] = uint256(chainlinkPrice);
        ds.switchboardPrice = prices[0];
        ds.pythPrice = prices[1];
        ds.chainlinkPrice = prices[2];

        ds.answer = median(prices);
        ds.variance = getVariance(prices);
    }

    function viewData() internal view returns (uint256 switchboardPrice, uint256 chainlinkPrice, uint256 pythPrice, uint256 answer, uint256 variance) {
        DiamondStorage storage ds = diamondStorage();
        switchboardPrice = ds.switchboardPrice;
        chainlinkPrice = ds.chainlinkPrice;
        pythPrice = ds.pythPrice;
        answer = ds.answer;
        variance = ds.variance;
    }


    function getVariance(uint256[] memory values) internal pure returns (uint256) {
        uint256 sum = 0;
        uint256 count = values.length;

        for(uint256 i = 0; i < count; i++) {
            sum += values[i];
        }

        uint256 average = sum / count;
        uint256 varianceSum = 0;

        for(uint256 i = 0; i < count; i++) {
            uint256 diff = values[i] > average ? values[i] - average : average - values[i];
            varianceSum += (diff * diff);
        }

        uint256 variance = varianceSum / count;

        return variance;
    }

    function sort(uint256[] memory arr) internal pure returns (uint256[] memory) {
        for (uint256 i = 1; i < arr.length; i++) {
            uint256 key = arr[i];
            uint256 j = i;
            while (j > 0 && arr[j - 1] > key) {
                arr[j] = arr[j - 1];
                j--;
            }
            arr[j] = key;
        }
        return arr;
    }

    function median(uint256[] memory arr) internal pure returns (uint256) {
        arr = sort(arr);
        uint256 len = arr.length;
        if (len % 2 == 1) {
            return arr[len / 2];
        } else {
            return (arr[len / 2] + arr[len / 2 - 1]) / 2;
        }
    }
}
