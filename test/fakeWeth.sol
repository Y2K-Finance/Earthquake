pragma solidity 0.8.15;
import {ERC20} from "@solmate/tokens/ERC20.sol";

contract WETH is ERC20 {
    constructor() ERC20("Y2K", "Y2K", 18) {}

    function mint(address _sender) public {
        _mint(_sender, 100 ether);
    }
}
