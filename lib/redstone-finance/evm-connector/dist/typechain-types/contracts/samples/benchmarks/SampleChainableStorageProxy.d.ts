import type { BaseContract, BigNumber, BigNumberish, BytesLike, CallOverrides, ContractTransaction, Overrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../../common";
export interface SampleChainableStorageProxyInterface extends utils.Interface {
    functions: {
        "aggregateValues(uint256[])": FunctionFragment;
        "getAllMockAuthorised(address)": FunctionFragment;
        "getAllMockExceptLastOneAuthorised(address)": FunctionFragment;
        "getAuthorisedMockSignerIndex(address)": FunctionFragment;
        "getAuthorisedSignerIndex(address)": FunctionFragment;
        "getOracleValue(bytes32)": FunctionFragment;
        "getOracleValues(bytes32[])": FunctionFragment;
        "getUniqueSignersThreshold()": FunctionFragment;
        "oracleValues(bytes32)": FunctionFragment;
        "processOracleValue(bytes32)": FunctionFragment;
        "processOracleValues(bytes32[])": FunctionFragment;
        "register(address)": FunctionFragment;
        "saveOracleValueInContractStorage(bytes32)": FunctionFragment;
        "saveOracleValuesInContractStorage(bytes32[])": FunctionFragment;
        "updateUniqueSignersThreshold(uint8)": FunctionFragment;
        "validateTimestamp(uint256)": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "aggregateValues" | "getAllMockAuthorised" | "getAllMockExceptLastOneAuthorised" | "getAuthorisedMockSignerIndex" | "getAuthorisedSignerIndex" | "getOracleValue" | "getOracleValues" | "getUniqueSignersThreshold" | "oracleValues" | "processOracleValue" | "processOracleValues" | "register" | "saveOracleValueInContractStorage" | "saveOracleValuesInContractStorage" | "updateUniqueSignersThreshold" | "validateTimestamp"): FunctionFragment;
    encodeFunctionData(functionFragment: "aggregateValues", values: [PromiseOrValue<BigNumberish>[]]): string;
    encodeFunctionData(functionFragment: "getAllMockAuthorised", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAllMockExceptLastOneAuthorised", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAuthorisedMockSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAuthorisedSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getOracleValue", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "getOracleValues", values: [PromiseOrValue<BytesLike>[]]): string;
    encodeFunctionData(functionFragment: "getUniqueSignersThreshold", values?: undefined): string;
    encodeFunctionData(functionFragment: "oracleValues", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "processOracleValue", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "processOracleValues", values: [PromiseOrValue<BytesLike>[]]): string;
    encodeFunctionData(functionFragment: "register", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "saveOracleValueInContractStorage", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "saveOracleValuesInContractStorage", values: [PromiseOrValue<BytesLike>[]]): string;
    encodeFunctionData(functionFragment: "updateUniqueSignersThreshold", values: [PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "validateTimestamp", values: [PromiseOrValue<BigNumberish>]): string;
    decodeFunctionResult(functionFragment: "aggregateValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAllMockAuthorised", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAllMockExceptLastOneAuthorised", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedMockSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getOracleValue", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getOracleValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getUniqueSignersThreshold", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "oracleValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "processOracleValue", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "processOracleValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "register", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "saveOracleValueInContractStorage", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "saveOracleValuesInContractStorage", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "updateUniqueSignersThreshold", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "validateTimestamp", data: BytesLike): Result;
    events: {};
}
export interface SampleChainableStorageProxy extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: SampleChainableStorageProxyInterface;
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
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<[BigNumber]>;
        getOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<[BigNumber[]]>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<[number]>;
        oracleValues(arg0: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<[BigNumber]>;
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        register(_sampleContract: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        saveOracleValuesInContractStorage(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        updateUniqueSignersThreshold(newUniqueSignersThreshold: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[void]>;
    };
    aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
    getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
    getOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<BigNumber[]>;
    getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
    oracleValues(arg0: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
    processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    register(_sampleContract: PromiseOrValue<string>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    saveOracleValuesInContractStorage(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    updateUniqueSignersThreshold(newUniqueSignersThreshold: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    callStatic: {
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        getOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<BigNumber[]>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
        oracleValues(arg0: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<void>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<void>;
        register(_sampleContract: PromiseOrValue<string>, overrides?: CallOverrides): Promise<void>;
        saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<void>;
        saveOracleValuesInContractStorage(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<void>;
        updateUniqueSignersThreshold(newUniqueSignersThreshold: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    };
    filters: {};
    estimateGas: {
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        getOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<BigNumber>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<BigNumber>;
        oracleValues(arg0: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        register(_sampleContract: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        saveOracleValuesInContractStorage(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        updateUniqueSignersThreshold(newUniqueSignersThreshold: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
    };
    populateTransaction: {
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        oracleValues(arg0: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        register(_sampleContract: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        saveOracleValuesInContractStorage(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        updateUniqueSignersThreshold(newUniqueSignersThreshold: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=SampleChainableStorageProxy.d.ts.map