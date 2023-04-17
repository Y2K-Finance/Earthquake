import type { BaseContract, BigNumber, BigNumberish, BytesLike, CallOverrides, ContractTransaction, Overrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../../common";
export interface StorageStructureModelInterface extends utils.Interface {
    functions: {
        "aggregateValues(uint256[])": FunctionFragment;
        "executeRequestWith10ArgsWithPrices(uint256)": FunctionFragment;
        "executeRequestWith3ArgsWithPrices(uint256)": FunctionFragment;
        "executeRequestWith5ArgsWithPrices(uint256)": FunctionFragment;
        "getAllMockAuthorised(address)": FunctionFragment;
        "getAllMockExceptLastOneAuthorised(address)": FunctionFragment;
        "getAuthorisedMockSignerIndex(address)": FunctionFragment;
        "getAuthorisedSignerIndex(address)": FunctionFragment;
        "getUniqueSignersThreshold()": FunctionFragment;
        "requestsWith10Args(uint256)": FunctionFragment;
        "requestsWith3Args(uint256)": FunctionFragment;
        "requestsWith5Args(uint256)": FunctionFragment;
        "sendRequestWith10Args(bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32)": FunctionFragment;
        "sendRequestWith3Args(bytes32,bytes32,bytes32)": FunctionFragment;
        "sendRequestWith5Args(bytes32,bytes32,bytes32,bytes32,bytes32)": FunctionFragment;
        "setDeleteFromStorage(bool)": FunctionFragment;
        "validateTimestamp(uint256)": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "aggregateValues" | "executeRequestWith10ArgsWithPrices" | "executeRequestWith3ArgsWithPrices" | "executeRequestWith5ArgsWithPrices" | "getAllMockAuthorised" | "getAllMockExceptLastOneAuthorised" | "getAuthorisedMockSignerIndex" | "getAuthorisedSignerIndex" | "getUniqueSignersThreshold" | "requestsWith10Args" | "requestsWith3Args" | "requestsWith5Args" | "sendRequestWith10Args" | "sendRequestWith3Args" | "sendRequestWith5Args" | "setDeleteFromStorage" | "validateTimestamp"): FunctionFragment;
    encodeFunctionData(functionFragment: "aggregateValues", values: [PromiseOrValue<BigNumberish>[]]): string;
    encodeFunctionData(functionFragment: "executeRequestWith10ArgsWithPrices", values: [PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "executeRequestWith3ArgsWithPrices", values: [PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "executeRequestWith5ArgsWithPrices", values: [PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "getAllMockAuthorised", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAllMockExceptLastOneAuthorised", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAuthorisedMockSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAuthorisedSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getUniqueSignersThreshold", values?: undefined): string;
    encodeFunctionData(functionFragment: "requestsWith10Args", values: [PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "requestsWith3Args", values: [PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "requestsWith5Args", values: [PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "sendRequestWith10Args", values: [
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>
    ]): string;
    encodeFunctionData(functionFragment: "sendRequestWith3Args", values: [
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>
    ]): string;
    encodeFunctionData(functionFragment: "sendRequestWith5Args", values: [
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BytesLike>
    ]): string;
    encodeFunctionData(functionFragment: "setDeleteFromStorage", values: [PromiseOrValue<boolean>]): string;
    encodeFunctionData(functionFragment: "validateTimestamp", values: [PromiseOrValue<BigNumberish>]): string;
    decodeFunctionResult(functionFragment: "aggregateValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "executeRequestWith10ArgsWithPrices", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "executeRequestWith3ArgsWithPrices", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "executeRequestWith5ArgsWithPrices", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAllMockAuthorised", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAllMockExceptLastOneAuthorised", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedMockSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getUniqueSignersThreshold", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "requestsWith10Args", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "requestsWith3Args", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "requestsWith5Args", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "sendRequestWith10Args", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "sendRequestWith3Args", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "sendRequestWith5Args", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "setDeleteFromStorage", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "validateTimestamp", data: BytesLike): Result;
    events: {};
}
export interface StorageStructureModel extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: StorageStructureModelInterface;
    queryFilter<TEvent extends TypedEvent>(event: TypedEventFilter<TEvent>, fromBlockOrBlockhash?: string | number | undefined, toBlock?: string | number | undefined): Promise<Array<TEvent>>;
    listeners<TEvent extends TypedEvent>(eventFilter?: TypedEventFilter<TEvent>): Array<TypedListener<TEvent>>;
    listeners(eventName?: string): Array<Listener>;
    removeAllListeners<TEvent extends TypedEvent>(eventFilter: TypedEventFilter<TEvent>): this;
    removeAllListeners(eventName?: string): this;
    off: OnEvent<this>;
    on: OnEvent<this>;
    once: OnEvent<this>;
    removeListener: OnEvent<this>;
    functions: {
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<[BigNumber]>;
        executeRequestWith10ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        executeRequestWith3ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        executeRequestWith5ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<[number]>;
        requestsWith10Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[
            string,
            string,
            string,
            string,
            string,
            string,
            string,
            string,
            string,
            string,
            BigNumber,
            string
        ] & {
            arg1: string;
            arg2: string;
            arg3: string;
            arg4: string;
            arg5: string;
            arg6: string;
            arg7: string;
            arg8: string;
            arg9: string;
            arg10: string;
            blockNumber: BigNumber;
            requesterAddress: string;
        }>;
        requestsWith3Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[
            string,
            string,
            string,
            BigNumber,
            string
        ] & {
            arg1: string;
            arg2: string;
            arg3: string;
            blockNumber: BigNumber;
            requesterAddress: string;
        }>;
        requestsWith5Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[
            string,
            string,
            string,
            string,
            string,
            BigNumber,
            string
        ] & {
            arg1: string;
            arg2: string;
            arg3: string;
            arg4: string;
            arg5: string;
            blockNumber: BigNumber;
            requesterAddress: string;
        }>;
        sendRequestWith10Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, arg4: PromiseOrValue<BytesLike>, arg5: PromiseOrValue<BytesLike>, arg6: PromiseOrValue<BytesLike>, arg7: PromiseOrValue<BytesLike>, arg8: PromiseOrValue<BytesLike>, arg9: PromiseOrValue<BytesLike>, arg10: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        sendRequestWith3Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        sendRequestWith5Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, arg4: PromiseOrValue<BytesLike>, arg5: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        setDeleteFromStorage(_deleteFromStorage: PromiseOrValue<boolean>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[void]>;
    };
    aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
    executeRequestWith10ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    executeRequestWith3ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    executeRequestWith5ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
    requestsWith10Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[
        string,
        string,
        string,
        string,
        string,
        string,
        string,
        string,
        string,
        string,
        BigNumber,
        string
    ] & {
        arg1: string;
        arg2: string;
        arg3: string;
        arg4: string;
        arg5: string;
        arg6: string;
        arg7: string;
        arg8: string;
        arg9: string;
        arg10: string;
        blockNumber: BigNumber;
        requesterAddress: string;
    }>;
    requestsWith3Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[
        string,
        string,
        string,
        BigNumber,
        string
    ] & {
        arg1: string;
        arg2: string;
        arg3: string;
        blockNumber: BigNumber;
        requesterAddress: string;
    }>;
    requestsWith5Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[
        string,
        string,
        string,
        string,
        string,
        BigNumber,
        string
    ] & {
        arg1: string;
        arg2: string;
        arg3: string;
        arg4: string;
        arg5: string;
        blockNumber: BigNumber;
        requesterAddress: string;
    }>;
    sendRequestWith10Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, arg4: PromiseOrValue<BytesLike>, arg5: PromiseOrValue<BytesLike>, arg6: PromiseOrValue<BytesLike>, arg7: PromiseOrValue<BytesLike>, arg8: PromiseOrValue<BytesLike>, arg9: PromiseOrValue<BytesLike>, arg10: PromiseOrValue<BytesLike>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    sendRequestWith3Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    sendRequestWith5Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, arg4: PromiseOrValue<BytesLike>, arg5: PromiseOrValue<BytesLike>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    setDeleteFromStorage(_deleteFromStorage: PromiseOrValue<boolean>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    callStatic: {
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        executeRequestWith10ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        executeRequestWith3ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        executeRequestWith5ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
        requestsWith10Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[
            string,
            string,
            string,
            string,
            string,
            string,
            string,
            string,
            string,
            string,
            BigNumber,
            string
        ] & {
            arg1: string;
            arg2: string;
            arg3: string;
            arg4: string;
            arg5: string;
            arg6: string;
            arg7: string;
            arg8: string;
            arg9: string;
            arg10: string;
            blockNumber: BigNumber;
            requesterAddress: string;
        }>;
        requestsWith3Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[
            string,
            string,
            string,
            BigNumber,
            string
        ] & {
            arg1: string;
            arg2: string;
            arg3: string;
            blockNumber: BigNumber;
            requesterAddress: string;
        }>;
        requestsWith5Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[
            string,
            string,
            string,
            string,
            string,
            BigNumber,
            string
        ] & {
            arg1: string;
            arg2: string;
            arg3: string;
            arg4: string;
            arg5: string;
            blockNumber: BigNumber;
            requesterAddress: string;
        }>;
        sendRequestWith10Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, arg4: PromiseOrValue<BytesLike>, arg5: PromiseOrValue<BytesLike>, arg6: PromiseOrValue<BytesLike>, arg7: PromiseOrValue<BytesLike>, arg8: PromiseOrValue<BytesLike>, arg9: PromiseOrValue<BytesLike>, arg10: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        sendRequestWith3Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        sendRequestWith5Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, arg4: PromiseOrValue<BytesLike>, arg5: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        setDeleteFromStorage(_deleteFromStorage: PromiseOrValue<boolean>, overrides?: CallOverrides): Promise<void>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    };
    filters: {};
    estimateGas: {
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        executeRequestWith10ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        executeRequestWith3ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        executeRequestWith5ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<BigNumber>;
        requestsWith10Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
        requestsWith3Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
        requestsWith5Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
        sendRequestWith10Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, arg4: PromiseOrValue<BytesLike>, arg5: PromiseOrValue<BytesLike>, arg6: PromiseOrValue<BytesLike>, arg7: PromiseOrValue<BytesLike>, arg8: PromiseOrValue<BytesLike>, arg9: PromiseOrValue<BytesLike>, arg10: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        sendRequestWith3Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        sendRequestWith5Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, arg4: PromiseOrValue<BytesLike>, arg5: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        setDeleteFromStorage(_deleteFromStorage: PromiseOrValue<boolean>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
    };
    populateTransaction: {
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
        executeRequestWith10ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        executeRequestWith3ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        executeRequestWith5ArgsWithPrices(requestId: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        requestsWith10Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        requestsWith3Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        requestsWith5Args(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        sendRequestWith10Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, arg4: PromiseOrValue<BytesLike>, arg5: PromiseOrValue<BytesLike>, arg6: PromiseOrValue<BytesLike>, arg7: PromiseOrValue<BytesLike>, arg8: PromiseOrValue<BytesLike>, arg9: PromiseOrValue<BytesLike>, arg10: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        sendRequestWith3Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        sendRequestWith5Args(arg1: PromiseOrValue<BytesLike>, arg2: PromiseOrValue<BytesLike>, arg3: PromiseOrValue<BytesLike>, arg4: PromiseOrValue<BytesLike>, arg5: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        setDeleteFromStorage(_deleteFromStorage: PromiseOrValue<boolean>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=StorageStructureModel.d.ts.map