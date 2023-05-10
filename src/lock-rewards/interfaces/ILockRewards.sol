// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ILockRewards {
    // Functions
    function balanceOf(address owner) external view returns (uint256);

    function balanceOfInEpoch(address owner, uint256 epochId)
        external
        view
        returns (uint256);

    function totalLocked() external view returns (uint256);

    function getCurrentEpoch()
        external
        view
        returns (
            uint256 start,
            uint256 finish,
            uint256 locked,
            uint256 rewards1,
            uint256 rewards2,
            bool isSet
        );

    function getNextEpoch()
        external
        view
        returns (
            uint256 start,
            uint256 finish,
            uint256 locked,
            uint256 rewards1,
            uint256 rewards2,
            bool isSet
        );

    function getEpoch(uint256 epochId)
        external
        view
        returns (
            uint256 start,
            uint256 finish,
            uint256 locked,
            uint256 rewards1,
            uint256 rewards2,
            bool isSet
        );

    function getAccount(address owner)
        external
        view
        returns (
            uint256 balance,
            uint256 lockEpochs,
            uint256 lastEpochPaid,
            uint256 rewards1,
            uint256 rewards2
        );

    function getEpochAccountInfo(address owner, uint256 epochId)
        external
        view
        returns (
            uint256 balance,
            uint256 start,
            uint256 finish,
            uint256 locked,
            uint256 userRewards1,
            uint256 userRewards2,
            bool isSet
        );

    function updateAccount()
        external
        returns (
            uint256 balance,
            uint256 lockEpochs,
            uint256 lastEpochPaid,
            uint256 rewards1,
            uint256 rewards2
        );

    function deposit(uint256 amount, uint256 lockEpochs) external;

    function withdraw(uint256 amount) external;

    function claimReward() external returns (uint256, uint256);

    function exit() external returns (uint256, uint256);

    function setNextEpoch(
        uint256 reward1,
        uint256 reward2,
        uint256 epochDurationInDays
    ) external;

    function setNextEpoch_start(
        uint256 reward1,
        uint256 reward2,
        uint256 epochDurationInDays,
        uint256 epochStart
    ) external;

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function changeRecoverWhitelist(address tokenAddress, bool flag) external;

    function recoverERC721(address tokenAddress, uint256 tokenId) external;

    function changeEnforceTime(bool flag) external;

    function changeMaxEpochs(uint256 _maxEpochs) external;

    // Events
    event Deposit(address indexed user, uint256 amount, uint256 lockedEpochs);
    event Relock(
        address indexed user,
        uint256 totalBalance,
        uint256 lockedEpochs
    );
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address token, uint256 reward);
    event SetNextReward(
        uint256 indexed epochId,
        uint256 reward1,
        uint256 reward2,
        uint256 start,
        uint256 finish
    );
    event RecoveredERC20(address token, uint256 amount);
    event RecoveredERC721(address token, uint256 tokenId);
    event ChangeERC20Whiltelist(address token, bool tokenState);
    event ChangeEnforceTime(uint256 indexed currentTime, bool flag);
    event ChangeMaxLockEpochs(
        uint256 indexed currentTime,
        uint256 oldEpochs,
        uint256 newEpochs
    );
    event UpdatedEpoch(uint256 currentId);
    // Errors
    error InsufficientAmount();
    error InsufficientBalance();
    error FundsInLockPeriod(uint256 balance);
    error InsufficientFundsForRewards(
        address token,
        uint256 available,
        uint256 rewardAmount
    );
    error LockEpochsMax(uint256 maxEpochs);
    error LockEpochsMin(uint256 minEpochs);
    error NotWhitelisted();
    error CannotWhitelistGovernanceToken(address governanceToken);
    error EpochMaxReached(uint256 maxEpochs);
    error EpochStartInvalid(uint256 epochStart, uint256 now);
    error IncreaseLockEpochsNotGTZero();

    // Structs
    struct Account {
        uint256 balance;
        uint256 lockEpochs;
        uint256 lastEpochPaid;
        uint256 rewards1;
        uint256 rewards2;
    }

    struct Epoch {
        mapping(address => uint256) balanceLocked;
        uint256 start;
        uint256 finish;
        uint256 totalLocked;
        uint256 rewards1;
        uint256 rewards2;
        bool isSet;
    }

    struct RewardToken {
        address addr;
        uint256 rewards;
        uint256 rewardsPaid;
    }
}
