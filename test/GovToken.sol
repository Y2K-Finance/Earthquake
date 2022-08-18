pragma solidity 0.8.15;
import {ERC20} from "@solmate/tokens/ERC20.sol";

contract GovToken is ERC20 {
    constructor() ERC20("Y2K", "Y2K", 18) {}

    function moneyPrinterGoesBrr(address _sender) public {
        _mint(_sender, 100 ether);
    }
}
