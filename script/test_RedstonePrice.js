// testPrice.js

//const { ethers } = require("ethers");
//const { WrapperBuilder } = require("@redstone-finance/evm-connector");

async function main() {
  
  if (process.argv.length < 4) {
    console.error('Error: Two positional arguments are required. (see test_RedstonePrice.js)');
    process.exit(1);
  }
  const rpcUrl = process.argv[2];
  const privateKey = process.argv[3];
  const contractAddress = process.argv[4];
  
  // Replace with your values
  //const privateKey = "";
  //const wallet = new ethers.Wallet(privateKey, provider);
  
  /*
  const rpcUrl = "https://goerli.infura.io/v3/37519f5fe2fb4d2cac2711a66aa06514";
  const contractAddress = "0x11Cc82544253565beB74faeda687db72cd2D5d32";

  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    
  const abi =require("../abi/RedstonePriceProvider.sol/RedstonePriceProvider.json");
    
  const contract = new ethers.Contract(contractAddress, abi["abi"], wallet);
  
  const wrappedContract = WrapperBuilder.wrap(contract).usingDataService({
    dataServiceId: "redstone-rapid-demo",
    uniqueSignersCount: 1,
    dataFeeds: ["VST"],
  }, ["https://d33trozg86ya9x.cloudfront.net"]);

  const ethPriceFromContract = await wrappedContract.getLatestPrice(ethers.constants.AddressZero);
  console.log({ ethPriceFromContract });
  */
  console.log(contractAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => { 
    console.error(error);
    process.exit(1);
  });
