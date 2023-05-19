// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICarousel {
    // function name() external view  returns (string memory);
    // function symbol() external view  returns (string memory);
    function asset() external view  returns (address);

    function token() external view returns (address);

    function strike() external view returns (uint256);

    function controller() external view returns (address);

    function counterPartyVault() external view returns (address);

    function getEpochConfig(uint256) external view returns (uint40, uint40);

    function totalAssets(uint256) external view returns (uint256);

    function epochExists(uint256 _id) external view returns (bool);

    function epochResolved(uint256 _id) external view returns (bool);

    function finalTVL(uint256 _id) external view returns (uint256);

    function claimTVL(uint256 _id) external view returns (uint256);

    function setEpoch(
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint256 _epochId
    ) external;

    function deposit(
        uint256 id,
        uint256 amount,
        address receiver
    ) external;

    function resolveEpoch(uint256 _id) external;

    function setClaimTVL(uint256 _id, uint256 _amount) external;

    function changeController(address _controller) external;

    function sendTokens(
        uint256 _id,
        uint256 _amount,
        address _receiver
    ) external;

    function whiteListAddress(address _treasury) external;

    function setCounterPartyVault(address _counterPartyVault) external;

    function setEpochNull(uint256 _id) external;

    function whitelistedAddresses(address _address)
        external
        view
        returns (bool);

    function enListInRollover(
        uint256 _assets,
        uint256 _epochId,
        address _receiver
    ) external;

    function deListInRollover(address _receiver) external;

    function mintDepositInQueue(uint256 _epochId, uint256 _operations) external;

    function mintRollovers(uint256 _epochId, uint256 _operations) external;

    function setEmissions(uint256 _epochId, uint256 _emissionsRate) external;

    function previewEmissionsWithdraw(uint256 _id, uint256 _assets) external;

    function changeRelayerFee(uint256 _relayerFee) external;

    function changeDepositFee(uint256 _depositFee) external;

    function changeTreasury(address) external;

    function balanceOfEmissoins(address _user, uint256 _epochId)
        external
        view
        returns (uint256);

    function emissionsToken() external view returns (address);

    function relayerFee() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function emissions(uint256 _epochId) external view returns (uint256);

    function cleanupRolloverQueue(address[] memory) external;

    function getDepositQueueLength() external view returns (uint256);

    function getRolloverQueueLength() external view returns (uint256);

    function getRolloverTVL() external view returns (uint256);

    function getDepositQueueTVL() external view returns (uint256);

    function rolloverAccounting(uint256 _epochId)
        external
        view
        returns (uint256);
}
