"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.runDryRun = void 0;
const runDryRun = async ({ functionName, contract, transaction, redstonePayload, }) => {
    const transactionToTest = Object.assign({}, transaction);
    transactionToTest.data = transactionToTest.data + redstonePayload;
    const result = await contract.provider.call(transactionToTest);
    contract.interface.decodeFunctionResult(functionName, result);
};
exports.runDryRun = runDryRun;
//# sourceMappingURL=run-dry-run.js.map