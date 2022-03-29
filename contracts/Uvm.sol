// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Uvm {
    IERC20 bolts;
    IERC20 scrwes;

    constructor(address BoltsToken, address ScrewsToken) {
        bolts = IERC20(BoltsToken);
        scrwes = IERC20(ScrewsToken);
    }
}
