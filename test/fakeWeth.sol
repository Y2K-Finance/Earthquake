pragma solidity 0.8.15;
import {ERC20} from "@solmate/tokens/ERC20.sol";

/// @author MiguelBits

contract WETH is ERC20 {
    constructor() ERC20("WETH", "WETH", 18) {}

    function mint(address _sender) public {
        _mint(_sender, 100 ether);
    }
    
    function deposit() payable public {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint amount) public{
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}
