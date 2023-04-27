"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.server = void 0;
const node_1 = require("msw/node");
const msw_1 = require("msw");
const redstone_protocol_1 = require("redstone-protocol");
const test_utils_1 = require("../../src/helpers/test-utils");
const VERIFIED_ADDRESS = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
const handlers = [
    msw_1.rest.get("http://first-node.com/score-by-address", async (req, res, ctx) => {
        const signedDataPackage = getSignedDataPackage({
            request: req,
            privateKey: test_utils_1.MOCK_PRIVATE_KEYS[1],
            valueBasedOnAddress: true,
        });
        return res(ctx.json(signedDataPackage.toObj()));
    }),
    msw_1.rest.get("http://second-node.com/score-by-address", async (req, res, ctx) => {
        const signedDataPackage = getSignedDataPackage({
            request: req,
            privateKey: test_utils_1.MOCK_PRIVATE_KEYS[2],
            valueBasedOnAddress: true,
        });
        return res(ctx.json(signedDataPackage.toObj()));
    }),
    msw_1.rest.get("http://invalid-address-node.com/score-by-address", async (req, res, ctx) => {
        const signedDataPackage = getSignedDataPackage({
            request: req,
            value: 1234,
            privateKey: test_utils_1.MOCK_PRIVATE_KEYS[2],
            dataFeedId: "invalid data feed id",
        });
        return res(ctx.json(signedDataPackage.toObj()));
    }),
    msw_1.rest.get("http://invalid-value-node.com/score-by-address", async (req, res, ctx) => {
        const signedDataPackage = getSignedDataPackage({
            request: req,
            value: 1234,
            privateKey: test_utils_1.MOCK_PRIVATE_KEYS[2],
        });
        return res(ctx.json(signedDataPackage.toObj()));
    }),
];
const getSignedDataPackage = ({ request, privateKey, value = 0, dataFeedId, valueBasedOnAddress = false, }) => {
    var _a, _b;
    const timestamp = (_a = request.url.searchParams.get("timestamp")) !== null && _a !== void 0 ? _a : "";
    const signature = (_b = request.url.searchParams.get("signature")) !== null && _b !== void 0 ? _b : "";
    const message = (0, redstone_protocol_1.prepareMessageToSign)(Number(timestamp));
    const address = redstone_protocol_1.UniversalSigner.recoverAddressFromEthereumHashMessage(message, signature);
    let valueToResponse = value;
    if (valueBasedOnAddress) {
        valueToResponse = address === VERIFIED_ADDRESS ? 1 : 0;
    }
    return (0, redstone_protocol_1.signOnDemandDataPackage)(!!dataFeedId ? dataFeedId : address, valueToResponse, Number(timestamp), privateKey);
};
exports.server = (0, node_1.setupServer)(...handlers);
//# sourceMappingURL=mock-server.js.map