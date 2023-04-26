"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BaseWrapper = void 0;
const ethers_1 = require("ethers");
const add_contract_wait_1 = require("../helpers/add-contract-wait");
class BaseWrapper {
    overwriteEthersContract(contract) {
        const contractPrototype = Object.getPrototypeOf(contract);
        const wrappedContract = Object.assign(Object.create(contractPrototype), contract, { populateTransaction: {} });
        const functionNames = Object.keys(contract.functions);
        functionNames.forEach((functionName) => {
            if (!functionName.includes("(")) {
                // It's important to overwrite the `populateTransaction`
                // function before overwriting the contract function,
                // because the updated implementation of the contract function
                // expects that the `populateTransaction` will return tx with
                // an attached redstone payload
                this.overwritePopulateTranasction({
                    wrappedContract,
                    contract,
                    functionName,
                });
                this.overwriteFunction({ wrappedContract, contract, functionName });
            }
        });
        return wrappedContract;
    }
    overwritePopulateTranasction({ wrappedContract, contract, functionName, }) {
        wrappedContract.populateTransaction[functionName] = async (...args) => {
            const originalTx = await contract.populateTransaction[functionName](...args);
            const dataToAppend = await this.getBytesDataForAppending({
                functionName,
                contract,
                transaction: originalTx,
            });
            originalTx.data += dataToAppend;
            return originalTx;
        };
    }
    overwriteFunction({ wrappedContract, contract, functionName, }) {
        const isCall = contract.interface.getFunction(functionName).constant;
        const isDryRun = functionName.endsWith("DryRun");
        wrappedContract[functionName] = async (...args) => {
            const tx = await wrappedContract.populateTransaction[functionName](...args);
            if (isCall || isDryRun) {
                const shouldUseSigner = ethers_1.Signer.isSigner(contract.signer);
                const result = await contract[shouldUseSigner ? "signer" : "provider"].call(tx);
                const decoded = contract.interface.decodeFunctionResult(functionName, result);
                return decoded.length == 1 ? decoded[0] : decoded;
            }
            else {
                const sentTx = await contract.signer.sendTransaction(tx);
                // Tweak the tx.wait so the receipt has extra properties
                (0, add_contract_wait_1.addContractWait)(contract, sentTx);
                return sentTx;
            }
        };
    }
}
exports.BaseWrapper = BaseWrapper;
//# sourceMappingURL=BaseWrapper.js.map