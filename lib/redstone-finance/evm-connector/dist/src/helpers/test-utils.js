"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRange = exports.getMockPackageWithOneBytesDataPoint = exports.getMockPackageWithOneNumericDataPoint = exports.getMockStringPackage = exports.getMockNumericPackage = exports.getMockSignedDataPackageObj = exports.getMockPackage = exports.getMockSignerAddress = exports.getMockSignerPrivateKey = exports.MOCK_SIGNERS = exports.MOCK_PRIVATE_KEYS = exports.DEFAULT_DATA_FEED_ID_BYTES_32 = exports.DEFAULT_DATA_FEED_ID = exports.DEFAULT_TIMESTAMP_FOR_TESTS = exports.MAX_MOCK_SIGNERS_COUNT = void 0;
const bytes_1 = require("@ethersproject/bytes");
const ethers_1 = require("ethers");
const redstone_protocol_1 = require("redstone-protocol");
exports.MAX_MOCK_SIGNERS_COUNT = 19;
// We lock the timestamp to have deterministic gas consumption
// for being able to compare gas costs of different implementations
exports.DEFAULT_TIMESTAMP_FOR_TESTS = 1654353400000;
// Default data feed id
// Used in mock data packages with one data point
exports.DEFAULT_DATA_FEED_ID = "SOME LONG STRING FOR DATA FEED ID TO TRIGGER SYMBOL HASHING";
exports.DEFAULT_DATA_FEED_ID_BYTES_32 = redstone_protocol_1.utils.convertStringToBytes32(exports.DEFAULT_DATA_FEED_ID);
// Well-known private keys, which are used by
// default in hardhat testing environment
exports.MOCK_PRIVATE_KEYS = [];
// Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
exports.MOCK_PRIVATE_KEYS[0] =
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
// Address: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
exports.MOCK_PRIVATE_KEYS[1] =
    "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
// Address: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
exports.MOCK_PRIVATE_KEYS[2] =
    "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";
// Address: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
exports.MOCK_PRIVATE_KEYS[3] =
    "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6";
// Address: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
exports.MOCK_PRIVATE_KEYS[4] =
    "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a";
// Address: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc
exports.MOCK_PRIVATE_KEYS[5] =
    "0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba";
// Address: 0x976EA74026E726554dB657fA54763abd0C3a0aa9
exports.MOCK_PRIVATE_KEYS[6] =
    "0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e";
// Address: 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955
exports.MOCK_PRIVATE_KEYS[7] =
    "0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356";
// Address: 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f
exports.MOCK_PRIVATE_KEYS[8] =
    "0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97";
// Address: 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
exports.MOCK_PRIVATE_KEYS[9] =
    "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6";
// Address: 0xBcd4042DE499D14e55001CcbB24a551F3b954096
exports.MOCK_PRIVATE_KEYS[10] =
    "0xf214f2b2cd398c806f84e317254e0f0b801d0643303237d97a22a48e01628897";
// Address: 0x71bE63f3384f5fb98995898A86B02Fb2426c5788
exports.MOCK_PRIVATE_KEYS[11] =
    "0x701b615bbdfb9de65240bc28bd21bbc0d996645a3dd57e7b12bc2bdf6f192c82";
// Address: 0xFABB0ac9d68B0B445fB7357272Ff202C5651694a
exports.MOCK_PRIVATE_KEYS[12] =
    "0xa267530f49f8280200edf313ee7af6b827f2a8bce2897751d06a843f644967b1";
// Address: 0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec
exports.MOCK_PRIVATE_KEYS[13] =
    "0x47c99abed3324a2707c28affff1267e45918ec8c3f20b8aa892e8b065d2942dd";
// Address: 0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097
exports.MOCK_PRIVATE_KEYS[14] =
    "0xc526ee95bf44d8fc405a158bb884d9d1238d99f0612e9f33d006bb0789009aaa";
// Address: 0xcd3B766CCDd6AE721141F452C550Ca635964ce71
exports.MOCK_PRIVATE_KEYS[15] =
    "0x8166f546bab6da521a8369cab06c5d2b9e46670292d85c875ee9ec20e84ffb61";
// Address: 0x2546BcD3c84621e976D8185a91A922aE77ECEc30
exports.MOCK_PRIVATE_KEYS[16] =
    "0xea6c44ac03bff858b476bba40716402b03e41b8e97e276d1baec7c37d42484a0";
// Address: 0xbDA5747bFD65F08deb54cb465eB87D40e51B197E
exports.MOCK_PRIVATE_KEYS[17] =
    "0x689af8efa8c651a91ad287602527f3af2fe9f6501a7ac4b061667b5a93e037fd";
// Address: 0xdD2FD4581271e230360230F9337D5c0430Bf44C0
exports.MOCK_PRIVATE_KEYS[18] =
    "0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0";
// Address: 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199
exports.MOCK_PRIVATE_KEYS[19] =
    "0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e";
exports.MOCK_SIGNERS = exports.MOCK_PRIVATE_KEYS.map((privateKey) => new ethers_1.ethers.Wallet(privateKey));
const getMockSignerPrivateKey = (mockSignerAddress) => {
    for (const privateKey of exports.MOCK_PRIVATE_KEYS) {
        const address = new ethers_1.ethers.Wallet(privateKey).address;
        if (address === mockSignerAddress) {
            return privateKey;
        }
    }
    throw new Error(`Invalid mock signer address: ${mockSignerAddress}`);
};
exports.getMockSignerPrivateKey = getMockSignerPrivateKey;
const getMockSignerAddress = (signerIndex) => {
    const address = new ethers_1.ethers.Wallet(exports.MOCK_PRIVATE_KEYS[signerIndex]).address;
    return address;
};
exports.getMockSignerAddress = getMockSignerAddress;
const getMockPackage = (opts, dataPoints) => {
    const timestampMilliseconds = opts.timestampMilliseconds || exports.DEFAULT_TIMESTAMP_FOR_TESTS;
    return {
        signer: exports.MOCK_SIGNERS[opts.mockSignerIndex].address,
        dataPackage: new redstone_protocol_1.DataPackage(dataPoints, timestampMilliseconds),
    };
};
exports.getMockPackage = getMockPackage;
const getMockSignedDataPackageObj = (args) => {
    const numericDataPoints = args.dataPoints.map((dp) => new redstone_protocol_1.NumericDataPoint(dp));
    const mockPackage = (0, exports.getMockPackage)(args, numericDataPoints);
    return {
        ...mockPackage.dataPackage
            .sign(exports.MOCK_SIGNERS[args.mockSignerIndex].privateKey)
            .toObj(),
    };
};
exports.getMockSignedDataPackageObj = getMockSignedDataPackageObj;
const getMockNumericPackage = (args) => {
    const numericDataPoints = args.dataPoints.map((dp) => new redstone_protocol_1.NumericDataPoint(dp));
    return (0, exports.getMockPackage)(args, numericDataPoints);
};
exports.getMockNumericPackage = getMockNumericPackage;
const getMockStringPackage = (args) => {
    const stringDataPoints = args.dataPoints.map((dp) => new redstone_protocol_1.StringDataPoint(dp));
    return (0, exports.getMockPackage)(args, stringDataPoints);
};
exports.getMockStringPackage = getMockStringPackage;
const getMockPackageWithOneNumericDataPoint = (args) => {
    const numericDataPoint = new redstone_protocol_1.NumericDataPoint({
        ...args,
        dataFeedId: args.dataFeedId || exports.DEFAULT_DATA_FEED_ID,
    });
    return (0, exports.getMockPackage)(args, [numericDataPoint]);
};
exports.getMockPackageWithOneNumericDataPoint = getMockPackageWithOneNumericDataPoint;
const getMockPackageWithOneBytesDataPoint = (args) => {
    const dataPoint = new redstone_protocol_1.DataPoint(args.dataFeedId || exports.DEFAULT_DATA_FEED_ID, (0, bytes_1.arrayify)(args.hexValue));
    return (0, exports.getMockPackage)(args, [dataPoint]);
};
exports.getMockPackageWithOneBytesDataPoint = getMockPackageWithOneBytesDataPoint;
// Prepares an array with sequential numbers
const getRange = (rangeArgs) => {
    return [...Array(rangeArgs.length).keys()].map((i) => (i += rangeArgs.start));
};
exports.getRange = getRange;
//# sourceMappingURL=test-utils.js.map