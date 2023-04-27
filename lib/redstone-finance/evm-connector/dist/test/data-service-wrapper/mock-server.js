"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.server = void 0;
const node_1 = require("msw/node");
const msw_1 = require("msw");
const tests_common_1 = require("../tests-common");
const singedDataPackageObj = tests_common_1.mockSignedDataPackageObjects;
const getDataPackageResponse = (dataFeedId) => singedDataPackageObj.filter((obj) => obj.dataPoints.filter((dp) => dp.dataFeedId === dataFeedId).length > 0);
const getValidDataPackagesResponse = () => ({
    ETH: getDataPackageResponse("ETH"),
    BTC: getDataPackageResponse("BTC"),
});
const handlers = [
    msw_1.rest.get("http://valid-cache.com/data-packages/latest/*", async (req, res, ctx) => {
        return res(ctx.json(getValidDataPackagesResponse()));
    }),
    msw_1.rest.get("http://invalid-cache.com/data-packages/latest/*", async (req, res, ctx) => {
        return res(ctx.json({
            ETH: getDataPackageResponse("ETH").map((obj) => ({
                ...obj,
                timestampMilliseconds: 1654353411111,
            })),
            BTC: getDataPackageResponse("BTC").map((obj) => ({
                ...obj,
                timestampMilliseconds: 1654353411111,
            })),
        }));
    }),
    msw_1.rest.get("http://slower-cache.com/data-packages/latest/*", async (req, res, ctx) => {
        return res(ctx.delay(200), ctx.json(getValidDataPackagesResponse()));
    }),
];
exports.server = (0, node_1.setupServer)(...handlers);
//# sourceMappingURL=mock-server.js.map