//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console } from "forge-std/Script.sol";
import { KipuBank } from "../contracts/KipuBank.sol";

contract DeployKipuBank is Script {
    address public deployer;
    KipuBank public kipuBank;

    function run() external {

        vm.startBroadcast();
        kipuBank = new KipuBank(10 ether);
        console.log("KipuBank deployed at:", address(kipuBank));
        vm.stopBroadcast();
    }
}