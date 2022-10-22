// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @author MiguelBits
contract Vault {

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error AddressZero();
    error AddressNotFactory(address _contract);
    error AddressNotController(address _contract);
    error MarketEpochDoesNotExist();
    error EpochAlreadyStarted();
    error EpochNotFinished();
    error FeeMoreThan150(uint256 _fee);
    error ZeroValue();
    error OwnerDidNotAuthorize(address _sender, address _owner);
    error EpochEndMustBeAfterBegin();
    error MarketEpochExists();
    error FeeCannotBe0();

    /*///////////////////////////////////////////////////////////////
                                AND STORAGE
    //////////////////////////////////////////////////////////////*/

    address public tokenInsured;
    address public treasury;
    int256 public strikePrice;
    address public factory;
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
    mapping(uint256 => bool) public idEpochEnded;
    // @audit id can be uint32
    mapping(uint256 => bool) public idExists;
    mapping(uint256 => uint256) public epochFee;
    mapping(uint256 => bool) public epochNull;

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @notice Deposit function from ERC4626, with payment of a fee to a treasury implemented;
        @param  id  uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
        @param  assets  uint256 representing how many assets the user wants to deposit, a fee will be taken from this value;
        @param receiver  address of the receiver of the assets provided by this function, that represent the ownership of the deposited asset;
     */
    function deposit(
        uint256 id,
        uint256 assets,
        address receiver
    )
        public
    {

    }

    /**
        @notice Deposit ETH function
        @param  id  uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
        @param receiver  address of the receiver of the shares provided by this function, that represent the ownership of the deposited asset;
     */
    function depositETH(uint256 id, address receiver)
        external
        payable
       
    {
        
    }

    /**
    @notice Withdraw entitled deposited assets, checking if a depeg event
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
        returns (uint256 shares)
    {
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
        returns (uint256)
    {
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

    }

    /*///////////////////////////////////////////////////////////////
                           Factory FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Factory function, changes treasury address
    @param _treasury New treasury address
     */
    function changeTreasury(address _treasury) public  {
    }

    /**
    @notice Factory function, changes vault time window
    @param _timewindow New vault time window
     */
    function changeTimewindow(uint256 _timewindow) public {
    }

    /**
    @notice Factory function, changes controller address
    @param _controller New controller address
     */
    function changeController(address _controller) public {

    }

    /**
    @notice Function to deploy hedge assets for given epochs, after the creation of this vault
    @param  epochBegin uint256 in UNIX timestamp, representing the begin date of the epoch. Example: Epoch begins in 31/May/2022 at 00h 00min 00sec: 1654038000
    @param  epochEnd uint256 in UNIX timestamp, representing the end date of the epoch and also the ID for the minting functions. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1656630000
    @param _withdrawalFee uint256 of the fee value, multiply your % value by 10, Example: if you want fee of 0.5% , insert 5
     */
    function createAssets(uint256 epochBegin, uint256 epochEnd, uint256 _withdrawalFee)
        public
        
    {
    }


    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/
    /**
        @notice Shows assets conversion output from withdrawing assets
        @param  id uint256 token id of token
        @param assets Total number of assets
     */
    function previewWithdraw(uint256 id, uint256 assets)
        public
        view
        returns (uint256 entitledAmount)
    {
        // in case the risk wins aka no depeg event
        // risk users can withdraw the hedge (that is paid by the hedge buyers) and risk; withdraw = (risk + hedge)
        // hedge pay for each hedge seller = ( risk / tvl before the hedge payouts ) * tvl in hedge pool
        // in case there is a depeg event, the risk users can only withdraw the hedge
        // in case the hedge wins aka depegging
        // hedge users pay the hedge to risk users anyway,
        // hedge guy can withdraw risk (that is transfered from the risk pool),
        // withdraw = % tvl that hedge buyer owns
        // otherwise hedge users cannot withdraw any Eth
    }
    
    /** @notice Lookup total epochs length
      */
    function epochsLength() public view returns (uint256) {
        return epochs.length;
    }

}
