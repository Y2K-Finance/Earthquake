"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getValidDataPackagesResponse = void 0;
const tests_common_1 = require("../tests-common");
const redstone_protocol_1 = require("redstone-protocol");
const singedDataPackageObj = tests_common_1.mockSignedDataPackageObjects;
const getDataPackageResponse = (dataFeedId) => singedDataPackageObj
    .filter((dataPackage) => dataPackage.dataPoints.filter((dp) => dp.dataFeedId === dataFeedId)
    .length > 0)
    .map((dataPackage) => redstone_protocol_1.SignedDataPackage.fromObj(dataPackage));
const getValidDataPackagesResponse = () => ({
    ETH: getDataPackageResponse("ETH"),
    BTC: getDataPackageResponse("BTC"),
});
exports.getValidDataPackagesResponse = getValidDataPackagesResponse;
//# sourceMappingURL=helpers.js.map