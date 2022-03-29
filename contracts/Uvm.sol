// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Uvm {
    IERC20 bolts;
    IERC20 screws;

    constructor(address BoltsToken, address ScrewsToken) {
        bolts = IERC20(BoltsToken);
        screws = IERC20(ScrewsToken);
    }

    struct Account {
        uint256 timestampForInterests; // We need this to calculate interests
    }

    mapping(address => Account) private accounts;

    event BoughtBolts(uint256 amount);
    event SoldBolts(uint256 amount);
}

//CONNECTED TO THE ACCOUNT STRUCT
function buyBolts(uint256 amountTobuy, address _tokenAddress) public payable {
    uint256 dexBalance = bolts.balanceOf(_tokenAddress);
    console.log(dexBalance);
    require(amountTobuy > 0, "You need to send some Ether");
    require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
    bolts.transfer(msg.sender, amountTobuy);
    emit BoughtBolts(amountTobuy);
}

//     function sellBolts(uint256 amount) public {
//         require(amount > 0, "add more value");
//         uint256 allowance = bolts.allowance(msg.sender, address(this));
//         require(allowance >= amount, "Check the token allowance");
//         bolts.transferFrom(msg.sender, address(this), amount);
//         payable(msg.sender).transfer(amount);
//         emit SoldBolts(amount);
//     }
// }
