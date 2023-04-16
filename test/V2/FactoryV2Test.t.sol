// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Helper.sol";
import "../../src/v2/VaultFactoryV2.sol";
import "../../src/v2/VaultV2.sol";
import "../../src/v2/TimeLock.sol";
import "../../src/v2/interfaces/IVaultV2.sol";

contract TimeLockV1 {
    mapping(bytes32 => bool) public queued;

    address public policy;

    uint256 public constant MIN_DELAY = 7 days;
    uint256 public constant MAX_DELAY = 30 days;
    uint256 public constant GRACE_PERIOD = 14 days;

    error NotOwner(address sender);
    error AlreadyQueuedError(bytes32 txId);
    error TimestampNotInRangeError(uint256 blocktimestamp, uint256 timestamp);
    error NotQueuedError(bytes32 txId);
    error TimestampNotPassedError(uint256 blocktimestamp, uint256 timestamp);
    error TimestampExpiredError(uint256 blocktimestamp, uint256 timestamp);
    error TxFailedError(string func);

    event Queue(
        bytes32 indexed txId,
        address indexed target,
        string func,
        uint256 index,
        uint256 data,
        address to,
        address token,
        uint256 timestamp
    );

    event Execute(
        bytes32 indexed txId,
        address indexed target,
        string func,
        uint256 index,
        uint256 data,
        address to,
        address token,
        uint256 timestamp
    );

    event Delete(
        bytes32 indexed txId,
        address indexed target,
        string func,
        uint256 index,
        uint256 data,
        address to,
        address token,
        uint256 timestamp
    );

    modifier onlyOwner() {
        if (msg.sender != policy) revert NotOwner(msg.sender);
        _;
    }

    constructor(address _policy) {
        policy = _policy;
    }

    /**
     * @dev leave params zero if not using them
     * @notice Queue a transaction
     * @param _target The target contract
     * @param _func The function to call
     * @param _index The market index of the vault to call the function on
     * @param _data The data to pass to the function
     * @param _to The address to change the params to
     * @param _token The token to change the params to
     * @param _timestamp The timestamp to execute the transaction
     */
    function queue(
        address _target,
        string calldata _func,
        uint256 _index,
        uint256 _data,
        address _to,
        address _token,
        uint256 _timestamp
    ) external onlyOwner {
        //create tx id
        bytes32 txId = getTxId(
            _target,
            _func,
            _index,
            _data,
            _to,
            _token,
            _timestamp
        );

        //check tx id unique
        if (queued[txId]) {
            revert AlreadyQueuedError(txId);
        }

        //check timestamp
        if (
            _timestamp < block.timestamp + MIN_DELAY ||
            _timestamp > block.timestamp + MAX_DELAY
        ) {
            revert TimestampNotInRangeError(block.timestamp, _timestamp);
        }

        //queue tx
        queued[txId] = true;

        emit Queue(
            txId,
            _target,
            _func,
            _index,
            _data,
            _to,
            _token,
            _timestamp
        );
    }

    /**
     * @dev leave params zero if not using them
     * @notice Execute a Queued a transaction
     * @param _target The target contract
     * @param _func The function to call
     * @param _index The market index of the vault to call the function on
     * @param _data The data to pass to the function
     * @param _to The address to change the params to
     * @param _token The token to change the params to
     * @param _timestamp The timestamp after which to execute the transaction
     */
    function execute(
        address _target,
        string calldata _func,
        uint256 _index,
        uint256 _data,
        address _to,
        address _token,
        uint256 _timestamp
    ) external onlyOwner {
        bytes32 txId = getTxId(
            _target,
            _func,
            _index,
            _data,
            _to,
            _token,
            _timestamp
        );

        //check tx id queued
        if (!queued[txId]) {
            revert NotQueuedError(txId);
        }

        //check block.timestamp > timestamp
        if (block.timestamp < _timestamp) {
            revert TimestampNotPassedError(block.timestamp, _timestamp);
        }
        if (block.timestamp > _timestamp + GRACE_PERIOD) {
            revert TimestampExpiredError(
                block.timestamp,
                _timestamp + GRACE_PERIOD
            );
        }

        //delete tx from queue
        queued[txId] = false;

        //execute tx
        if (compareStringsbyBytes(_func, "changeTreasury")) {
            // VaultFactoryV2(_target).changeTreasury(_to, _index);
        } else if (compareStringsbyBytes(_func, "changeController")) {
            VaultFactoryV2(_target).changeController(_index, _to);
        } else if (compareStringsbyBytes(_func, "changeOracle")) {
            VaultFactoryV2(_target).changeOracle(_token, _to);
        } else {
            revert TxFailedError(_func);
        }

        emit Execute(
            txId,
            _target,
            _func,
            _index,
            _data,
            _to,
            _token,
            _timestamp
        );
    }

    function cancel(
        address _target,
        string calldata _func,
        uint256 _index,
        uint256 _data,
        address _to,
        address _token,
        uint256 _timestamp
    ) external onlyOwner {
        bytes32 txId = getTxId(
            _target,
            _func,
            _index,
            _data,
            _to,
            _token,
            _timestamp
        );

        //check tx id queued
        if (!queued[txId]) {
            revert NotQueuedError(txId);
        }

        //delete tx from queue
        queued[txId] = false;

        emit Delete(
            txId,
            _target,
            _func,
            _index,
            _data,
            _to,
            _token,
            _timestamp
        );
    }

    function getTxId(
        address _target,
        string calldata _func,
        uint256 _index,
        uint256 _data,
        address _to,
        address _token,
        uint256 _timestamp
    ) public pure returns (bytes32 txId) {
        return
            keccak256(
                abi.encode(
                    _target,
                    _func,
                    _index,
                    _data,
                    _to,
                    _token,
                    _timestamp
                )
            );
    }

    function compareStringsbyBytes(string memory s1, string memory s2)
        public
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function changeOwner(address _newOwner) external onlyOwner {
        policy = _newOwner;
    }
}

contract FactoryV2Test is Helper {
      VaultFactoryV2 factory;
      address controller;
      function setUp() public {

        TimeLock timelock = new TimeLock(ADMIN);

        factory = new VaultFactoryV2(
            WETH,
            TREASURY,
            address(timelock)
        );

        controller = address(0x54);
        factory.whitelistController(address(controller));
     }

    function testOneTimelock() public {
        string memory arbitrumRpcUrl = vm.envString("ARBITRUM_RPC_URL");
        uint256 arbForkId = vm.createFork(arbitrumRpcUrl);
        vm.selectFork(arbForkId);

        TimeLockV1 t = TimeLockV1(0xdf468f3FCCa9FC6Cb51241A139a2Eb53971D8f81);
        factory = VaultFactoryV2(0x984E0EB8fB687aFa53fc8B33E12E04967560E092);
        bytes memory data = bytes("0x4dc809ce0000000000000000000000005979d7b546e38e414f7e9822514be443a4800529000000000000000000000000ded2c52b75b24732e9107377b7ba93ec1ffa4baf");
        // immulate timelocker address 
        vm.startPrank(0x16cBaDA408F7523452fF91c8387b1784d00d10D8);

        uint256 timestamp = block.timestamp + 7 days + 1 seconds;

        t.queue(
            address(factory),
            "changeOracle",
            0,
            0,
            0xded2c52b75B24732e9107377B7Ba93eC1fFa4BAf,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            timestamp
        );

        bytes32 txId = t.getTxId(
             address(factory),
            "changeOracle",
            0,
            0,
            0xded2c52b75B24732e9107377B7Ba93eC1fFa4BAf,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            timestamp
        );

        vm.warp(timestamp - 1 seconds);

        console.logBytes32(txId);

        t.execute(
            address(factory),
            "changeOracle",
            0,
            0,
            0xded2c52b75B24732e9107377B7Ba93eC1fFa4BAf,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            timestamp
        );

        address newOracle = factory.tokenToOracle(0x5979D7b546E38E414F7E9822514be443A4800529);

        console.log(newOracle);

        
        assertTrue(newOracle == 0xded2c52b75B24732e9107377B7Ba93eC1fFa4BAf);


        // t.executeTransaction(address(factory), 0, data);
        // 0xdf468f3fcca9fc6cb51241a139a2eb53971d8f81 
        

    }

    function testFactoryCreation() public {

        TimeLock timelock = new TimeLock(ADMIN);

        factory = new VaultFactoryV2(
            WETH,
            TREASURY,
            address(timelock)
        );
       
        assertEq(address(timelock.policy()), ADMIN);
        assertEq(address(factory.WETH()), WETH);
        assertEq(address(factory.treasury()), TREASURY);
        assertEq(address(factory.owner()), address(this));

        // After deployment controller can be set one time by owner 
        vm.expectRevert(abi.encodeWithSelector(VaultFactoryV2.AddressZero.selector));
        factory.whitelistController(address(0));

        address controller1 = address(0x54);
        factory.whitelistController(address(controller1));
        assertTrue(factory.controllers(controller1));

        address controller2 = address(0x55);
        vm.expectRevert(abi.encodeWithSelector(VaultFactoryV2.NotAuthorized.selector));
        factory.whitelistController(controller2);

        // new controllers can be added by queueing them in tomelocker
        vm.startPrank(factory.timelocker());
        factory.whitelistController(controller2);
        assertTrue(factory.controllers(controller2));
        vm.stopPrank();
    }

    function testMarketCreation() public {
        
        // test all revert cases
        vm.startPrank(NOTADMIN);
            vm.expectRevert(bytes("Ownable: caller is not the owner"));
                factory.createNewMarket(
                   VaultFactoryV2.MarketConfigurationCalldata(
                        address(0x1),
                        uint256(0x2),
                        address(0x3),
                        address(0x4),
                        string(""),
                        string(""),
                        address(0x7) // wrong controller
                   )
                );
        vm.stopPrank();

        // wrong controller
        vm.expectRevert(VaultFactoryV2.ControllerNotSet.selector);
            factory.createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    address(0x1),
                    uint256(0x2),
                    address(0x3),
                    address(0x4),
                    string(""),
                    string(""),
                    address(0x7) // wrong controller
               )
            );

        address token = address(0x1);
        address oracle = address(0x3);
        address underlying = address(0x4);
        uint256 strike = uint256(0x2);
        string memory name = string("");
        string memory symbol = string("");
        // wrong token
        vm.expectRevert(VaultFactoryV2.AddressZero.selector);
            factory.createNewMarket(
               VaultFactoryV2.MarketConfigurationCalldata(
                    address(0), // wrong token
                    strike,
                    oracle,
                    underlying,
                    name,
                    symbol,
                    controller
               )
            );

       // wrong oracle
        vm.expectRevert(VaultFactoryV2.AddressZero.selector);
            factory.createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                     token,
                    strike,
                    address(0), // wrong oracle
                    underlying,
                    name,
                    symbol,
                    controller)
            );

        // wrong underlying
        vm.expectRevert(VaultFactoryV2.AddressZero.selector);
            factory.createNewMarket(
                VaultFactoryV2.MarketConfigurationCalldata(
                    token,
                    strike,
                    oracle,
                    address(0), // wrong underlying
                    name,
                    symbol,
                    controller)
            );


        // test success case
        (
            address premium,
            address collateral,
            uint256 marketId
        ) = factory.createNewMarket(
            VaultFactoryV2.MarketConfigurationCalldata(
                 token,
                strike,
                oracle,
                underlying,
                name,
                symbol,
                controller)
        );

        // test if market is created
        assertEq(factory.getVaults(marketId)[0], premium);
        assertEq(factory.getVaults(marketId)[1], collateral);

        // test oracle is set
        assertTrue(factory.tokenToOracle(token) == oracle);
        assertEq(marketId, factory.getMarketId(token, strike, underlying));

        // test if counterparty is set
        assertEq(IVaultV2(premium).counterPartyVault(), collateral);
        assertEq(IVaultV2(collateral).counterPartyVault(), premium);   
    }

    function testEpochDeloyment() public {
        // teste revert cases
        vm.startPrank(NOTADMIN);
            vm.expectRevert(bytes("Ownable: caller is not the owner"));
                factory.createEpoch(
                uint256(0x1),
                uint40(0x2),
                uint40(0x3),
                uint16(0x4)
                );
        vm.stopPrank();

        uint256 marketId = createMarketHelper();

        // test revert cases
        vm.expectRevert(abi.encodeWithSelector(VaultFactoryV2.MarketDoesNotExist.selector, uint256(0x1)));
            factory.createEpoch(
                uint256(0x1),// market does not exist
                uint40(0x2),
                uint40(0x3),
                uint16(0x4)
            );
  
        vm.expectRevert(VaultFactoryV2.FeeCannotBe0.selector);
            factory.createEpoch(
                marketId,
                uint40(0x2),
                uint40(0x3),
                uint16(0) // fee can not be 0
            );

        
        // make sure epoch can not be set if controller is deprecated
        address[2] memory vaults = factory.getVaults(marketId);
        vm.startPrank(address(factory.timelocker()));
            factory.whitelistController(controller);
        vm.stopPrank();
        vm.expectRevert(VaultFactoryV2.ControllerNotSet.selector);
            factory.createEpoch(
                marketId,
                uint40(0x2),
                uint40(0x3),
                uint16(0x4)
            );
        vm.startPrank(address(factory.timelocker()));
            factory.whitelistController(controller);
        vm.stopPrank();

        vm.expectRevert(VaultV2.EpochEndMustBeAfterBegin.selector);
            factory.createEpoch(
                marketId,
                uint40(0x5), // begin must be before end
                uint40(0x3),
                uint16(0x4)
            );

      ( uint256 epochId,) =  factory.createEpoch(
                marketId,
                uint40(0x2),
                uint40(0x3),
                uint16(0x4)
       );
       vm.expectRevert(VaultV2.EpochAlreadyExists.selector);
            factory.createEpoch(
                marketId,
                uint40(0x2),
                uint40(0x3),
                uint16(0x4)
            );

        // test success case
        uint40 begin = uint40(0x3);
        uint40 end = uint40(0x4);
        uint16 fee = uint16(0x5);

       ( uint256 epochId2,) =  factory.createEpoch(
                marketId,
                begin,
                end,
                fee
       );

        // test if epoch fee is correct
        uint16 fetchedFee = factory.getEpochFee(epochId2);
        assertEq(fee, fetchedFee);
        
        // test if epoch config is correct
        (uint40 fetchedBegin, uint40 fetchedEnd, ) = IVaultV2(vaults[0]).getEpochConfig(epochId2);
        assertEq(begin, fetchedBegin);
        assertEq(end, fetchedEnd);

        // test if epoch is added to market
        uint256[] memory epochs = factory.getEpochsByMarketId(marketId);
        assertEq(epochs[0], epochId);
        assertEq(epochs[1], epochId2);

    }
    
    function testSetTreasury() public {
        // test revert cases
        vm.expectRevert(VaultFactoryV2.NotTimeLocker.selector);
            factory.setTreasury(address(0x20));

        vm.startPrank(address(factory.timelocker()));
            vm.expectRevert(VaultFactoryV2.AddressZero.selector);
                factory.setTreasury(address(0));

            // test success case
            factory.setTreasury(address(0x20));
            assertEq(factory.treasury(), address(0x20));
        vm.stopPrank();
    }

    function testChangeController() public {
        address newController = address(0x20);
        // test revert cases
        uint256 marketId = createMarketHelper();
        vm.expectRevert(VaultFactoryV2.NotTimeLocker.selector);
            factory.changeController(marketId, newController);
        
        vm.startPrank(address(factory.timelocker()));
            vm.expectRevert(VaultFactoryV2.ControllerNotSet.selector);
                factory.changeController(marketId, newController);
            factory.whitelistController(newController);
            vm.expectRevert(abi.encodeWithSelector(VaultFactoryV2.MarketDoesNotExist.selector, uint256(0x1)));
                factory.changeController(uint256(0x1), newController);
       

            // test success case
            factory.changeController(marketId, newController);
            address[2] memory vaults = factory.getVaults(marketId);
            assertEq(IVaultV2(vaults[0]).controller(), newController);
            assertEq(IVaultV2(vaults[1]).controller(), newController);
        vm.stopPrank();
    }

    function testChangeOracle() public {
        // test revert cases
        address token = address(0x1);
        // address oldOracle = address(0x3);
        address newOracle = address(0x4);

        createMarketHelper();
        vm.expectRevert(VaultFactoryV2.NotTimeLocker.selector);
            factory.changeOracle(token,newOracle);

        vm.startPrank(address(factory.timelocker()));
            vm.expectRevert(VaultFactoryV2.AddressZero.selector);
                factory.changeOracle(address(0), newOracle);
            vm.expectRevert(VaultFactoryV2.AddressZero.selector);
                factory.changeOracle(token, address(0));
       

            // test success case
            factory.changeOracle(token, newOracle);
        vm.stopPrank();
        assertEq(factory.tokenToOracle(token), newOracle); 
    }

    function createMarketHelper() public returns(uint256 marketId){

        address token = address(0x1);
        address oracle = address(0x3);
        address underlying = address(0x4);
        uint256 strike = uint256(0x2);
        string memory name = string("test");
        string memory symbol = string("tst");

        (, ,marketId) = factory.createNewMarket(
            VaultFactoryV2.MarketConfigurationCalldata(
                token,
                strike,
                oracle,
                underlying,
                name,
                symbol,
                controller)
        );
    }
}