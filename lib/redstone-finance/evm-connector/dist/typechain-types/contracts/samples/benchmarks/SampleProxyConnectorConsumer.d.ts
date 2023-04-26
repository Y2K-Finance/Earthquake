import type { BaseContract, BigNumber, BigNumberish, BytesLike, CallOverrides, ContractTransaction, Overrides, PayableOverrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../../common";
export interface SampleProxyConnectorConsumerInterface extends utils.Interface {
    functions: {
        "aggregateValues(uint256[])": FunctionFragment;
        "getAllMockAuthorised(address)": FunctionFragment;
        "getAllMockExceptLastOneAuthorised(address)": FunctionFragment;
        "getAuthorisedMockSignerIndex(address)": FunctionFragment;
        "getAuthorisedSignerIndex(address)": FunctionFragment;
        "getComputationResult()": FunctionFragment;
        "getUniqueSignersThreshold()": FunctionFragment;
        "getValueForDataFeedId(bytes32)": FunctionFragment;
        "getValueManyParams(bytes32,uint256,string,string,string,string,string)": FunctionFragment;
        "getValuesForDataFeedIds(bytes32[])": FunctionFragment;
        "latestSavedValue()": FunctionFragment;
        "processOracleValue(bytes32)": FunctionFragment;
        "processOracleValues(bytes32[])": FunctionFragment;
        "returnMsgValue()": FunctionFragment;
        "revertWithTestMessage()": FunctionFragment;
        "revertWithoutMessage()": FunctionFragment;
        "saveOracleValueInContractStorage(bytes32)": FunctionFragment;
        "updateUniqueSignersThreshold(uint8)": FunctionFragment;
        "validateTimestamp(uint256)": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "aggregateValues" | "getAllMockAuthorised" | "getAllMockExceptLastOneAuthorised" | "getAuthorisedMockSignerIndex" | "getAuthorisedSignerIndex" | "getComputationResult" | "getUniqueSignersThreshold" | "getValueForDataFeedId" | "getValueManyParams" | "getValuesForDataFeedIds" | "latestSavedValue" | "processOracleValue" | "processOracleValues" | "returnMsgValue" | "revertWithTestMessage" | "revertWithoutMessage" | "saveOracleValueInContractStorage" | "updateUniqueSignersThreshold" | "validateTimestamp"): FunctionFragment;
    encodeFunctionData(functionFragment: "aggregateValues", values: [PromiseOrValue<BigNumberish>[]]): string;
    encodeFunctionData(functionFragment: "getAllMockAuthorised", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAllMockExceptLastOneAuthorised", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAuthorisedMockSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAuthorisedSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getComputationResult", values?: undefined): string;
    encodeFunctionData(functionFragment: "getUniqueSignersThreshold", values?: undefined): string;
    encodeFunctionData(functionFragment: "getValueForDataFeedId", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "getValueManyParams", values: [
        PromiseOrValue<BytesLike>,
        PromiseOrValue<BigNumberish>,
        PromiseOrValue<string>,
        PromiseOrValue<string>,
        PromiseOrValue<string>,
        PromiseOrValue<string>,
        PromiseOrValue<string>
    ]): string;
    encodeFunctionData(functionFragment: "getValuesForDataFeedIds", values: [PromiseOrValue<BytesLike>[]]): string;
    encodeFunctionData(functionFragment: "latestSavedValue", values?: undefined): string;
    encodeFunctionData(functionFragment: "processOracleValue", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "processOracleValues", values: [PromiseOrValue<BytesLike>[]]): string;
    encodeFunctionData(functionFragment: "returnMsgValue", values?: undefined): string;
    encodeFunctionData(functionFragment: "revertWithTestMessage", values?: undefined): string;
    encodeFunctionData(functionFragment: "revertWithoutMessage", values?: undefined): string;
    encodeFunctionData(functionFragment: "saveOracleValueInContractStorage", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "updateUniqueSignersThreshold", values: [PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "validateTimestamp", values: [PromiseOrValue<BigNumberish>]): string;
    decodeFunctionResult(functionFragment: "aggregateValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAllMockAuthorised", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAllMockExceptLastOneAuthorised", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedMockSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getComputationResult", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getUniqueSignersThreshold", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getValueForDataFeedId", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getValueManyParams", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getValuesForDataFeedIds", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "latestSavedValue", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "processOracleValue", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "processOracleValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "returnMsgValue", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "revertWithTestMessage", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "revertWithoutMessage", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "saveOracleValueInContractStorage", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "updateUniqueSignersThreshold", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "validateTimestamp", data: BytesLike): Result;
    events: {};
}
export interface SampleProxyConnectorConsumer extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: SampleProxyConnectorConsumerInterface;
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
        getComputationResult(overrides?: CallOverrides): Promise<[BigNumber]>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<[number]>;
        getValueForDataFeedId(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<[BigNumber]>;
        getValueManyParams(dataFeedId: PromiseOrValue<BytesLike>, mockArg1: PromiseOrValue<BigNumberish>, mockArg2: PromiseOrValue<string>, mockArg3: PromiseOrValue<string>, mockArg4: PromiseOrValue<string>, mockArg5: PromiseOrValue<string>, mockArg6: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[BigNumber]>;
        getValuesForDataFeedIds(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<[BigNumber[]]>;
        latestSavedValue(overrides?: CallOverrides): Promise<[BigNumber]>;
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        returnMsgValue(overrides?: PayableOverrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        revertWithTestMessage(overrides?: CallOverrides): Promise<[void]>;
        revertWithoutMessage(overrides?: CallOverrides): Promise<[void]>;
        saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
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
    getComputationResult(overrides?: CallOverrides): Promise<BigNumber>;
    getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
    getValueForDataFeedId(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
    getValueManyParams(dataFeedId: PromiseOrValue<BytesLike>, mockArg1: PromiseOrValue<BigNumberish>, mockArg2: PromiseOrValue<string>, mockArg3: PromiseOrValue<string>, mockArg4: PromiseOrValue<string>, mockArg5: PromiseOrValue<string>, mockArg6: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
    getValuesForDataFeedIds(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<BigNumber[]>;
    latestSavedValue(overrides?: CallOverrides): Promise<BigNumber>;
    processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    returnMsgValue(overrides?: PayableOverrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    revertWithTestMessage(overrides?: CallOverrides): Promise<void>;
    revertWithoutMessage(overrides?: CallOverrides): Promise<void>;
    saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
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
        getComputationResult(overrides?: CallOverrides): Promise<BigNumber>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
        getValueForDataFeedId(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        getValueManyParams(dataFeedId: PromiseOrValue<BytesLike>, mockArg1: PromiseOrValue<BigNumberish>, mockArg2: PromiseOrValue<string>, mockArg3: PromiseOrValue<string>, mockArg4: PromiseOrValue<string>, mockArg5: PromiseOrValue<string>, mockArg6: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getValuesForDataFeedIds(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<BigNumber[]>;
        latestSavedValue(overrides?: CallOverrides): Promise<BigNumber>;
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<void>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<void>;
        returnMsgValue(overrides?: CallOverrides): Promise<BigNumber>;
        revertWithTestMessage(overrides?: CallOverrides): Promise<void>;
        revertWithoutMessage(overrides?: CallOverrides): Promise<void>;
        saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<void>;
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
        getComputationResult(overrides?: CallOverrides): Promise<BigNumber>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<BigNumber>;
        getValueForDataFeedId(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        getValueManyParams(dataFeedId: PromiseOrValue<BytesLike>, mockArg1: PromiseOrValue<BigNumberish>, mockArg2: PromiseOrValue<string>, mockArg3: PromiseOrValue<string>, mockArg4: PromiseOrValue<string>, mockArg5: PromiseOrValue<string>, mockArg6: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getValuesForDataFeedIds(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<BigNumber>;
        latestSavedValue(overrides?: CallOverrides): Promise<BigNumber>;
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        returnMsgValue(overrides?: PayableOverrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        revertWithTestMessage(overrides?: CallOverrides): Promise<BigNumber>;
        revertWithoutMessage(overrides?: CallOverrides): Promise<BigNumber>;
        saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
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
        getComputationResult(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getValueForDataFeedId(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getValueManyParams(dataFeedId: PromiseOrValue<BytesLike>, mockArg1: PromiseOrValue<BigNumberish>, mockArg2: PromiseOrValue<string>, mockArg3: PromiseOrValue<string>, mockArg4: PromiseOrValue<string>, mockArg5: PromiseOrValue<string>, mockArg6: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getValuesForDataFeedIds(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
        latestSavedValue(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        processOracleValue(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        processOracleValues(dataFeedIds: PromiseOrValue<BytesLike>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        returnMsgValue(overrides?: PayableOverrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        revertWithTestMessage(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        revertWithoutMessage(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        saveOracleValueInContractStorage(dataFeedId: PromiseOrValue<BytesLike>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        updateUniqueSignersThreshold(newUniqueSignersThreshold: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=SampleProxyConnectorConsumer.d.ts.map