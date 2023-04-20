//const { ethers } = require("ethers");
const ethers = require("ethers");


const { WrapperBuilder } = require("@redstone-finance/evm-connector");


async function validate(){
  if (process.argv.length < 4) {
    console.error('Error: Two positional arguments are required. (see test_RedstonePrice.js)');
    process.exit(1);
  }
    
  const rpcUrl = process.argv[2];
  const privateKey = process.argv[3];
  const contractAddress = process.argv[4];
  const urlRegex = /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/;
  if (!urlRegex.test(rpcUrl)) {
    console.log('Error: Invalid rpcUrl.');
    process.exit(1);
  }

  const privateKeyRegex = /^0x[a-fA-F0-9]{64}$/;
  if (!privateKeyRegex.test(privateKey)) {
    console.log('Error: Invalid privateKey.');
    process.exit(1);
  }

  const addressRegex = /^0x[a-fA-F0-9]{40}$/;
  if (contractAddress && !addressRegex.test(contractAddress)) {
    console.log('Error: Invalid contractAddress.');
      process.exit(1);
  }
  return {rpcUrl:rpcUrl,
          privateKey:privateKey,
         contractAddress:contractAddress}

}

async function main() {
  
  const {rpcUrl,privateKey,contractAddress} = await validate();
  
  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);
  
  const abi =require("../abi/RedstonePriceProvider.sol/RedstonePriceProvider.json");
  const contract = new ethers.Contract(contractAddress, abi["abi"], wallet);
  
  const wrappedContract = WrapperBuilder.wrap(contract).usingDataService({
    dataServiceId: "redstone-rapid-demo",
    uniqueSignersCount: 1,
    dataFeeds: ["VST"],
  }, ["https://d33trozg86ya9x.cloudfront.net"]);

  const priceFromContract = await wrappedContract.getLatestPrice(ethers.constants.AddressZero);
  //console.log(priceFromContract);   
  const priceAsBigNumber = ethers.BigNumber.from(priceFromContract._hex);
  console.log(`P`+priceAsBigNumber.toString());  
    
  //console.log("rpcUrl",rpcUrl);
  //console.log("privateKey",privateKey);
  //console.log("contractAddress",contractAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => { 
    console.error(error);
    process.exit(1);
  });
