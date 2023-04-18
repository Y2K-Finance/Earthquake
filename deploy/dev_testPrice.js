// testPrice.js

const { ethers } = require("ethers");
const { WrapperBuilder } = require("@redstone-finance/evm-connector");

async function main() {
  // Replace with your values
  const rpcUrl = "https://goerli.infura.io/v3/37519f5fe2fb4d2cac2711a66aa06514";
  const privateKey = "0xa881e3de2f71ddfcd7d5c189c4755b6033328d48e9895d47ea4de00603d6732c";
  const contractAddress = "0x11Cc82544253565beB74faeda687db72cd2D5d32";

  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);
    
  const abi =require("../abi/RedstonePriceProvider.sol/RedstonePriceProvider.json");
    
  const contract = new ethers.Contract(contractAddress, abi["abi"], wallet);
  
  const wrappedContract = WrapperBuilder.wrap(contract).usingDataService({
    dataServiceId: "redstone-rapid-demo",
    uniqueSignersCount: 1,
    dataFeeds: ["VST"],
  }, ["https://d33trozg86ya9x.cloudfront.net"]);

  const ethPriceFromContract = await wrappedContract.getLatestPrice(ethers.constants.AddressZero);
  console.log({ ethPriceFromContract });
  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
