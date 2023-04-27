"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WrapperBuilder = void 0;
const MockWrapper_1 = require("./wrappers/MockWrapper");
const DataServiceWrapper_1 = require("./wrappers/DataServiceWrapper");
const SimpleMockNumericWrapper_1 = require("./wrappers/SimpleMockNumericWrapper");
const OnDemandRequestWrapper_1 = require("./wrappers/OnDemandRequestWrapper");
const DataPackagesWrapper_1 = require("./wrappers/DataPackagesWrapper");
class WrapperBuilder {
    constructor(baseContract) {
        this.baseContract = baseContract;
    }
    static wrap(contract) {
        return new WrapperBuilder(contract);
    }
    usingDataService(dataPackagesRequestParams, urls) {
        return new DataServiceWrapper_1.DataServiceWrapper(dataPackagesRequestParams, urls).overwriteEthersContract(this.baseContract);
    }
    usingMockDataPackages(mockDataPackages) {
        return new MockWrapper_1.MockWrapper(mockDataPackages).overwriteEthersContract(this.baseContract);
    }
    usingSimpleNumericMock(simpleNumericMockConfig) {
        return new SimpleMockNumericWrapper_1.SimpleNumericMockWrapper(simpleNumericMockConfig).overwriteEthersContract(this.baseContract);
    }
    usingOnDemandRequest(nodeUrls, scoreType) {
        return new OnDemandRequestWrapper_1.OnDemandRequestWrapper({
            signer: this.baseContract.signer,
            scoreType,
        }, nodeUrls).overwriteEthersContract(this.baseContract);
    }
    usingDataPackages(dataPackages) {
        return new DataPackagesWrapper_1.DataPackagesWrapper(dataPackages).overwriteEthersContract(this.baseContract);
    }
}
exports.WrapperBuilder = WrapperBuilder;
//# sourceMappingURL=WrapperBuilder.js.map