import { ethers } from "hardhat";
import moment from "moment-timezone";
import Big from "big.js";
const BigNumber = require("bignumber.js");

(async function main() {
  const sbPushAddress = process.env.EXAMPLE_PROGRAM ?? "";

  const divisor = new BigNumber("100000000");

  if (!sbPushAddress) {
    throw new Error(
      "Please set the diamond address with: export EXAMPLE_PROGRAM=..."
    );
  }

  const push = await ethers.getContractAt("Receiver", sbPushAddress);
  const p = await push.deployed();

  const [sb, cl, pyth, median, variance] = await p.viewData();
  console.log("============");
  console.log(`Switchboard: ${new Big(sb.toString()).div(divisor).toString()}`);
  console.log(`Chainlink: ${new Big(cl.toString()).div(divisor).toString()}`);
  console.log(`Pyth: ${new Big(pyth.toString()).div(divisor).toString()}`);
  console.log("============");
  console.log(`Median: ${new Big(median.toString()).div(divisor).toString()}`);
  console.log(
    `Variance: ${new Big(variance.toString()).div(divisor).div(divisor).toString()}`
  );
})();
