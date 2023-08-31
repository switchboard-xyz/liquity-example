//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ReceiverLib} from "./ReceiverLib.sol";
import {AdminLib} from "../admin/AdminLib.sol";
import {ErrorLib} from "../error/ErrorLib.sol";

// Get the Switchboard Library - this is the Core Mainnet Deployment, you can swap this for one of the networks below
import {Switchboard} from "@switchboard-xyz/evm.js/contracts/arbitrum/testnet/Switchboard.sol";

contract Receiver {

    function callback(address[] calldata chainlinkFeeds, bytes[] calldata pythVaas) external {
        address functionId = Switchboard.getEncodedFunctionId();
        if (AdminLib.functionId() == address(0)) {
            AdminLib.setFunctionId(functionId);
        }

        // Assert that the sender is switchboard & the correct function id is encoded
        if (functionId != AdminLib.functionId()) {
            revert ErrorLib.InvalidSender(AdminLib.functionId(), functionId);
        }
        // ReceiverLib.callback(data, timestamp);
    }

    function viewData() external view returns (int256, uint256) {
        return ReceiverLib.viewData();
    }
}
