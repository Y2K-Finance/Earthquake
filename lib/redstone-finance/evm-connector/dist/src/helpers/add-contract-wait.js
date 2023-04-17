"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.addContractWait = void 0;
const utils_1 = require("ethers/lib/utils");
// Copied from ethers.js source code
const addContractWait = (contract, tx) => {
    const wait = tx.wait.bind(tx);
    tx.wait = (confirmations) => {
        return wait(confirmations).then((receipt) => {
            receipt.events = receipt.logs.map((log) => {
                let event = (0, utils_1.deepCopy)(log);
                // let parsed: LogDescription = null;
                let parsed = null;
                try {
                    parsed = contract.interface.parseLog(log);
                }
                catch (e) { }
                // Successfully parsed the event log; include it
                if (parsed) {
                    event.args = parsed.args;
                    event.decode = (data, topics) => {
                        return contract.interface.decodeEventLog(parsed.eventFragment, data, topics);
                    };
                    event.event = parsed.name;
                    event.eventSignature = parsed.signature;
                }
                // Useful operations
                event.removeListener = () => {
                    return contract.provider;
                };
                event.getBlock = () => {
                    return contract.provider.getBlock(receipt.blockHash);
                };
                event.getTransaction = () => {
                    return contract.provider.getTransaction(receipt.transactionHash);
                };
                event.getTransactionReceipt = () => {
                    return Promise.resolve(receipt);
                };
                return event;
            });
            return receipt;
        });
    };
};
exports.addContractWait = addContractWait;
//# sourceMappingURL=add-contract-wait.js.map