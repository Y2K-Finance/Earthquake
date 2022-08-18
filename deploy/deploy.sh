## testnet Arbitrum

#Deploy Vault Factory
forge create --rpc-url https://rinkeby.arbitrum.io/rpc --private-key 0x28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733 src/VaultFactory.sol:VaultFactory --constructor-args "0xFB0a3A93e9acd461747e7D613eb3722d53B96613" "0x207eD1742cc0BeBD03E50e855d3a14E41f93A461" "0xFB0a3A93e9acd461747e7D613eb3722d53B96613"

#Deploy Gov Token
forge create --rpc-url https://rinkeby.arbitrum.io/rpc --private-key 0x28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733 test/GovToken.sol:GovToken

#Deploy Controller
#vault factory address
forge create --rpc-url https://rinkeby.arbitrum.io/rpc --private-key 0x28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733 src/Controller.sol:Controller --constructor-args 0x0905CDFa438191ECc1e8C0204b2fc867B26255A9

#Set Controller on Vault Factory
#Factory then controller address
cast send 0x0905CDFa438191ECc1e8C0204b2fc867B26255A9 "setController(address)" 0xbe1ab61fe7c1c9a30ddbad36e814926010ee9858 --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733

#Create New Market USDC in Vault
#factory address
cast send 0x0905CDFa438191ECc1e8C0204b2fc867B26255A9 "createNewMarket(uint256,uint256,address,int256,uint256,uint256,address,string)" 10 50 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926 99000000 1660171487 1661899487 0xe020609A0C31f4F96dCBB8DF9882218952dD95c4 "y2kUSDC_99*AUG" --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733

#Create New Market USDT in Vault
#factory address
cast send 0x0905CDFa438191ECc1e8C0204b2fc867B26255A9 "createNewMarket(uint256,uint256,address,int256,uint256,uint256,address,string)(address,address)" 10 50 0xb1Ac85E779d05C2901812d812210F6dE144b2df0 99000000 1658344223 1659381023 0x22052D9B926ae7a1dA56690155bbea736200cb20 "y2kUSDT_99*AUG" --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733

#Check Market Index
cast call 0x0905CDFa438191ECc1e8C0204b2fc867B26255A9 "marketIndex()(uint256)" --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733

#Get Vaults
#Factory address
cast call 0x0905CDFa438191ECc1e8C0204b2fc867B26255A9 "getVaults(uint256)(address[])" 1 --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733

#Check Oracle to Token
cast call 0x0905CDFa438191ECc1e8C0204b2fc867B26255A9 "tokenToOracle(address)(address)" 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926 --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733

#deploy more assets
cast send 0x0905CDFa438191ECc1e8C0204b2fc867B26255A9 "deployMoreAssets(uint256,uint256,uint256)" 1 1660160092 1662838492 --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733

#Check Price Token In Vault
cast call 0xe71e1983ced2872cc85b66062daf7123a3ae218a "getLatestPrice(address)(int256)"  0xeb8f08a975Ab53E34D8a0330E0D34de942C95926 --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733

#Controller TRIGGER
cast send 0xbe1ab61fe7c1c9a30ddbad36e814926010ee9858 "triggerDepeg(uint256,uint256)" 1 1662059423 --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733

cast send 0xbe1ab61fe7c1c9a30ddbad36e814926010ee9858 "triggerEndEpoch(uint256,uint256)" 1 1662059423 --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733

#Check Epoch ID In Vault
cast call 0x74db2902bb5d4390faf3f35783a9574b727b3643 "epochs()(uint256[])" --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733


#Create staking rewards Vaults
#forge create --rpc-url https://rinkeby.arbitrum.io/rpc --private-key 0x28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733 src/rewards/StakingRewards.sol:StakingRewards --constructor-args "0xEAE1f7b21B7f6c711C441d85eE5ab53E4A626D65" "0xEAE1f7b21B7f6c711C441d85eE5ab53E4A626D65" "Address Gov Token" "Address of Insurance Buyer/Seller Contract" "Epoch End Time"
#forge create --rpc-url https://rinkeby.arbitrum.io/rpc --private-key 0x28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733 src/rewards/StakingRewards.sol:StakingRewards --constructor-args "0xEAE1f7b21B7f6c711C441d85eE5ab53E4A626D65" "0xEAE1f7b21B7f6c711C441d85eE5ab53E4A626D65" 0x1f50c6aa35e03e7f6dfb832627cf6277fbd4a51a  0xe5593bceaca91cd0f30e1af5d763f89d17124530 1656598590
#forge create --rpc-url https://rinkeby.arbitrum.io/rpc --private-key 0x28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733 src/rewards/StakingRewards.sol:StakingRewards --constructor-args "0xEAE1f7b21B7f6c711C441d85eE5ab53E4A626D65" "0xEAE1f7b21B7f6c711C441d85eE5ab53E4A626D65" 0x1f50c6aa35e03e7f6dfb832627cf6277fbd4a51a  0xb514432638b157156d9c7c6249b3fc4951cb243a 1656598590

#Create staking rewards Factory, gov token then factory
forge create --rpc-url https://rinkeby.arbitrum.io/rpc --private-key 0x28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733 src/rewards/RewardsFactory.sol:RewardsFactory --constructor-args 0x0ff5be06e887c690b27b8c1a1806511748ffb56d 0x0905CDFa438191ECc1e8C0204b2fc867B26255A9

cast send 0xDAd186AE5e64e1eB8b3e867292fF390CEfB3973E "createStakingRewards(uint256,uint256)(address,address)" 1 1661899487 --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733
#cast send 0xDAd186AE5e64e1eB8b3e867292fF390CEfB3973E "createStakingRewards(uint256,uint256)(address,address)" 1 1662838492 --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733
cast send 0xDAd186AE5e64e1eB8b3e867292fF390CEfB3973E "createStakingRewards(uint256,uint256)(address,address)" 2 1661899487 --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733
cast send 0xDAd186AE5e64e1eB8b3e867292fF390CEfB3973E "createStakingRewards(uint256,uint256)(address,address)" 3 1661899487 --rpc-url https://rinkeby.arbitrum.io/rpc --private-key=28d5e6bc9e88e32a62c4c4d7638328f063a4659eebed036096daf96538b00733
