// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IVaultOverhaul {

  /**
        @notice initialize 
        @param  _assetAddress    token address representing your asset to be deposited;
        @param  _name   token name for the ERC1155 mints. Insert the name of your token; Example: Y2K_USDC_1.2$
        @param  _symbol token symbol for the ERC1155 mints. insert here if risk or hedge + Symbol. Example: HedgeY2K or riskY2K;
        @param  _token  address of the oracle to lookup the price in chainlink oracles;
        @param  _strikePrice    uint256 representing the price to trigger the depeg event;
        @param _controller  address of the controller contract, this contract can trigger the depeg events;
     */
  
    function initialize(
        address _assetAddress,
        string memory _name,
        string memory _symbol,
        address _token,
        int256 _strikePrice,
        address _controller
    ) external;
    

    function tokenInsured() external view returns (address);
    function strikePrice() external view returns (int256);
    function controller() external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function asset() external view returns (address);

    function idExists(uint40 _id) external view returns (bool);
    function idEpochBegin(uint40 _id) external view returns (uint256);
    function idEpochEnded(uint40 _id) external view returns (bool);
    function idFinalTVL(uint40 _id) external view returns (uint256);
    function idClaimTVL(uint40 _id) external view returns (uint256);

    function createAssets(uint40 _id, uint256 _amount) external;
    function endEpoch(uint40 _id) external;
    function setClaimTVL(uint40 _id, uint256 _amount) external;
    function changeController(address _controller) external;
    function sendTokens(address _receiver, uint40 _id, uint256 _amount) external;

}
