pragma solidity 0.8.15;
import {ERC20} from "@solmate/tokens/ERC20.sol";

contract GovToken is ERC20 {
    constructor() ERC20("Dumb", "Dumb", 18) {}

    function moneyPrinterGoesBrr(address _sender) public {
        _mint(_sender, 100 ether);
    }

    function mint(address _sender) public {
        _mint(_sender, 100 ether);
    }

    function mint(address _sender, uint256 _amount) public {
        _mint(_sender, _amount * 1 ether);
    }
}
