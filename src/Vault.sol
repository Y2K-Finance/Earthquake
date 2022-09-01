// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SemiFungibleVault} from "./SemiFungibleVault.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Vault is SemiFungibleVault, ReentrancyGuard {
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error AddressZero();
    error AddressNotFactory(address _contract);
    error AddressNotController(address _contract);
    error MarketEpochDoesNotExist(uint256 _epoch);
    error EpochAlreadyStarted(uint256 _epoch);
    error EpochNotFinished(uint256 _epoch);
    error FeeMoreThan150(uint256 _fee);
    error ZeroValue();
    error OwnerDidNotAuthorize(address _sender, address _owner);
    error EpochEndMustBeAfterBegin(uint256 _begin, uint256 _end);
    error MarketEpochExists(uint256 _epoch);

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES AND STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable tokenInsured;
    address private treasury;
    int256 public immutable strikePrice;
    address private immutable factory;
    address public controller;

    uint256[] public epochs;
    uint256 public timewindow;

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => uint256) public idFinalTVL;
    mapping(uint256 => uint256) public idClaimTVL;
    // @audit uint32 for timestamp is enough for the next 80 years
    mapping(uint256 => uint256) public idEpochBegin;
    // @audit id can be uint32
    mapping(uint256 => bool) public idDepegged;
    // @audit id can be uint32
    mapping(uint256 => bool) public idExists;
    mapping(uint256 => uint256) public epochFee;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /** @notice Only factory addresses can call functions that use this modifier
      */
    modifier onlyFactory() {
        if(msg.sender != factory)
            revert AddressNotFactory(msg.sender);
        _;
    }

    /** @notice Only controller addresses can call functions that use this modifier
      */
    modifier onlyController() {
        if(msg.sender != controller)
            revert AddressNotController(msg.sender);
        _;
    }

    /** @notice Only market addresses can call functions that use this modifier
      */
    modifier marketExists(uint256 id) {
        if(idExists[id] != true)
            revert MarketEpochDoesNotExist(id);
        _;
    }

    /** @notice You can only call functions that use this modifier before the current epoch has started
      */
    modifier epochHasNotStarted(uint256 id) {
        if(block.timestamp > idEpochBegin[id] - timewindow)
            revert EpochAlreadyStarted(id);
        _;
    }

    /** @notice You can only call functions that use this modifier after the current epoch has started
      */
    modifier epochHasEnded(uint256 id) {
        if((block.timestamp < id) && idDepegged[id] == false)
            revert EpochNotFinished(id);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
        @notice constructor
        @param  _assetAddress    token address representing your asset to be deposited;
        @param  _name   token name for the ERC1155 mints. Insert the name of your token; Example: Y2K_USDC_1.2$
        @param  _symbol token symbol for the ERC1155 mints. insert here if risk or hedge + Symbol. Example: HedgeY2K or riskY2K;
        @param  _token  address of the oracle to lookup the price in chainlink oracles;
        @param  _strikePrice    uint256 representing the price to trigger the depeg event;
        @param _controller  address of the controller contract, this contract can trigger the depeg events;
     */
    constructor(
        address _assetAddress,
        string memory _name,
        string memory _symbol,
        address _treasury,
        address _token,
        int256 _strikePrice,
        address _controller
    ) SemiFungibleVault(ERC20(_assetAddress), _name, _symbol) {

        if(_treasury == address(0))
            revert AddressZero();

        if(_controller == address(0))
            revert AddressZero();

        if(_token == address(0))
            revert AddressZero();

        tokenInsured = _token;
        treasury = _treasury;
        strikePrice = _strikePrice;
        factory = msg.sender;
        controller = _controller;
        timewindow = 1 days;
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @notice Deposit function from ERC4626, with payment of a fee to a treasury implemented;
        @param  id  uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
        @param  assets  uint256 representing how many assets the user wants to deposit, a fee will be taken from this value;
        @param receiver  address of the receiver of the shares provided by this function, that represent the ownership of the deposited asset;
        @return shares how many assets the owner is entitled to, removing the fee from it's shares;
     */
    function deposit(
        uint256 id,
        uint256 assets,
        address receiver
    )
        public
        override
        marketExists(id)
        epochHasNotStarted(id)
        nonReentrant
        returns (uint256 shares)
    {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(id, assets)) != 0, "ZeroValue");

        asset.transferFrom(msg.sender, address(this), shares);

        _mint(receiver, id, shares, EMPTY);

        emit Deposit(msg.sender, receiver, id, shares, shares);

        return shares;
    }

    /**
        @notice Deposit ETH function
        @param  id  uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
        @param receiver  address of the receiver of the shares provided by this function, that represent the ownership of the deposited asset;
        @return shares how many assets the owner is entitled to, removing the fee from its shares;
     */
    function depositETH(uint256 id, address receiver)
        external
        payable
        returns (uint256 shares)
    {
        require(msg.value > 0, "ZeroValue");

        IWETH(address(asset)).deposit{value: msg.value}();
        assert(IWETH(address(asset)).transfer(msg.sender, msg.value));

        return deposit(id, msg.value, receiver);
    }

    /**
    @notice Withdraw entitled deposited assets, checking if a depeg event //TODO add GOV token rewards
    @param  id uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
    @param assets   uint256 of how many assets you want to withdraw, this value will be used to calculate how many assets you are entitle to according to the events;
    @param receiver  Address of the receiver of the assets provided by this function, that represent the ownership of the transfered asset;
    @param owner    Address of the owner of these said assets;
    @return shares How many shares the owner is entitled to, according to the conditions;
     */
    function withdraw(
        uint256 id,
        uint256 assets,
        address receiver,
        address owner
    )
        external
        override
        epochHasEnded(id)
        marketExists(id)
        returns (uint256 shares)
    {
        if(
            msg.sender != owner || 
            isApprovedForAll(owner, receiver))
            revert OwnerDidNotAuthorize(msg.sender, owner);

        shares = previewWithdraw(id, assets); // No need to check for rounding error, previewWithdraw rounds up.

        uint256 entitledShares = beforeWithdraw(id, shares);
        _burn(owner, id, shares);

        //Taking fee from the amount
        uint256 feeValue = calculateWithdrawalFeeValue(entitledShares, id);
        entitledShares = entitledShares - feeValue;
        asset.transfer(treasury, feeValue);

        emit Withdraw(msg.sender, receiver, owner, id, assets, entitledShares);
        asset.transfer(receiver, entitledShares);

        return entitledShares;
    }

    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @notice returns total assets for the id of given epoch
        @param  _id uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
     */
    function totalAssets(uint256 _id)
        public
        view
        override
        marketExists(_id)
        returns (uint256)
    {
        return totalSupply(_id);
    }

    /**
    @notice Calculates how much ether the %fee is taking from @param amount
    @param amount Amount to withdraw from vault
    @param _epoch Target epoch
    @return feeValue Current fee value
     */
    function calculateWithdrawalFeeValue(uint256 amount, uint256 _epoch)
        public
        view
        returns (uint256 feeValue)
    {
        // 0.5% = multiply by 1000 then divide by 5
        return (amount * epochFee[_epoch]) / 1000;
    }

    /*///////////////////////////////////////////////////////////////
                           Factory FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Factory function, changes treasury address
    @param _treasury New treasury address
     */
    function changeTreasury(address _treasury) public onlyFactory {
        if(_treasury == address(0))
            revert AddressZero();
        treasury = _treasury;
    }

    /**
    @notice Factory function, changes vault time window
    @param _timewindow New vault time window
     */
    function changeTimewindow(uint256 _timewindow) public onlyFactory {
        timewindow = _timewindow;
    }

    /**
    @notice Factory function, changes controller address
    @param _controller New controller address
     */
    function changeController(address _controller) public onlyFactory {
        if(_controller == address(0))
            revert AddressZero();
        controller = _controller;
    }

    /**
    @notice Function to deploy hedge assets for given epochs, after the creation of this vault
    @param  epochBegin uint256 in UNIX timestamp, representing the begin date of the epoch. Example: Epoch begins in 31/May/2022 at 00h 00min 00sec: 1654038000
    @param  epochEnd uint256 in UNIX timestamp, representing the end date of the epoch and also the ID for the minting functions. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1656630000
    @param _withdrawalFee uint256 of the fee value, multiply your % value by 10, Example: if you want fee of 0.5% , insert 5
     */
    function createAssets(uint256 epochBegin, uint256 epochEnd, uint256 _withdrawalFee)
        public
        onlyFactory
    {
        if(_withdrawalFee > 150)
            revert FeeMoreThan150(_withdrawalFee);

        if(idExists[epochEnd] == true)
            revert MarketEpochExists(epochEnd);
        
        if(epochBegin >= epochEnd)
            revert EpochEndMustBeAfterBegin(epochBegin, epochEnd);

        idExists[epochEnd] = true;
        idEpochBegin[epochEnd] = epochBegin;
        epochs.push(epochEnd);

        epochFee[epochEnd] = _withdrawalFee;
    }

    /*///////////////////////////////////////////////////////////////
                         CONTROLLER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Controller can call this function to trigger the end of the epoch, storing the TVL of that epoch and if a depeg event occurred
    @param  id uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000
    @param depeg Boolean value indicating if the depeg event occurred, or not. Example: If depeg occurred depeg = true
     */
    function endEpoch(uint256 id, bool depeg)
        public
        onlyController
        marketExists(id)
    {
        idDepegged[id] = depeg;
        idFinalTVL[id] = totalAssets(id);
    }

    /**
    @notice Function to be called after endEpoch, by the Controller only, this function stores the TVL of the counterparty vault in a mapping to be used for later calculations of the entitled withdraw
    @param  id uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000
    @param claimTVL uint256 representing the TVL the counterparty vault has, storing this value in a mapping
     */
    function setClaimTVL(uint256 id, uint256 claimTVL) public onlyController {
        idClaimTVL[id] = claimTVL;
    }

    /**
    solhint-disable-next-line max-line-length
    @notice Function to be called after endEpoch and setClaimTVL functions, respecting the calls in order, after storing the TVL of the end of epoch and the TVL amount to claim, this function will allow the transfer of tokens to the counterparty vault
    @param  id uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000
    @param _counterparty Address of the other vault, meaning address of the risk vault, if this is an hedge vault, and vice-versa
    */
    function sendTokens(uint256 id, address _counterparty)
        public
        onlyController
        marketExists(id)
    {
        asset.transfer(_counterparty, idFinalTVL[id]);
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Calculations of how much the user will receive;
    @param  id uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000
    @param amount uint256 of the amount the user wants to withdraw
    @return entitledAmount How much amount the user will receive, according to the conditions
    */
    function beforeWithdraw(uint256 id, uint256 amount)
        public
        view
        returns (uint256 entitledAmount)
    {
        // in case the risk wins aka no depeg event
        // risk users can withdraw the hedge (that is paid by the hedge buyers) and risk; withdraw = (risk + hedge)
        // hedge pay for each hedge seller = ( risk / tvl before the hedge payouts ) * tvl in hedge pool
        // in case there is a depeg event, the risk users can only withdraw the hedge
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("rY2K"))
        ) {
            if (!idDepegged[id]) {
                //depeg event did not happen
                /*
                entitledAmount =
                    (amount / idFinalTVL[id]) *
                    idClaimTVL[id] +
                    amount;
                */
                entitledAmount =
                    amount.divWadDown(idFinalTVL[id]).mulDivDown(
                        idClaimTVL[id],
                        1 ether
                    ) +
                    amount;
            } else {
                //depeg event did happen
                entitledAmount = amount.divWadDown(idFinalTVL[id]).mulDivDown(
                    idClaimTVL[id],
                    1 ether
                );
            }
        }
        // in case the hedge wins aka depegging
        // hedge users pay the hedge to risk users anyway,
        // hedge guy can withdraw risk (that is transfered from the risk pool),
        // withdraw = % tvl that hedge buyer owns
        // otherwise hedge users cannot withdraw any Eth
        else {
            entitledAmount = amount.divWadDown(idFinalTVL[id]).mulDivDown(
                idClaimTVL[id],
                1 ether
            );
        }

        return entitledAmount;
    }
    
    /** @notice Lookup total epochs length
      */
    function epochsLength() public view returns (uint256) {
        return epochs.length;
    }

    /** @notice Lookup next epochs' end from target
        @param _epoch Target epoch
        @return nextEpochEnd Next epoch end
      */
    function getNextEpoch(uint256 _epoch)
        public
        view
        returns (uint256 nextEpochEnd)
    {
        for (uint256 i = 0; i < epochsLength(); i++) {
            if (epochs[i] == _epoch) {
                if (i == epochsLength() - 1) {
                    return 0;
                }
                return epochs[i + 1];
            }
        }
    }
}
