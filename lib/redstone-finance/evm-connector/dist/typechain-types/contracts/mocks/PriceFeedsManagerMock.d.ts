import type { BaseContract, BigNumber, BigNumberish, BytesLike, CallOverrides, ContractTransaction, Overrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result, EventFragment } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../common";
export interface PriceFeedsManagerMockInterface extends utils.Interface {
    functions: {
        "addDataFeedIdAndUpdateValues(bytes32,uint256)": FunctionFragment;
        "aggregateValues(uint256[])": FunctionFragment;
        "getAllMockAuthorised(address)": FunctionFragment;
        "getAllMockExceptLastOneAuthorised(address)": FunctionFragment;
        "getAuthorisedMockSignerIndex(address)": FunctionFragment;
        "getAuthorisedSignerIndex(address)": FunctionFragment;
        "getDataFeedsIds()": FunctionFragment;
        "getLastRound()": FunctionFragment;
        "getLastRoundParams()": FunctionFragment;
        "getLastUpdateTimestamp()": FunctionFragment;
        "getUniqueSignersThreshold()": FunctionFragment;
        "getValueForDataFeed(bytes32)": FunctionFragment;
        "getValueForDataFeedAndLastRoundParams(bytes32)": FunctionFragment;
        "getValuesForDataFeeds(bytes32[])": FunctionFragment;
        "lastRound()": FunctionFragment;
        "lastUpdateTimestampMilliseconds()": FunctionFragment;
        "owner()": FunctionFragment;
        "renounceOwnership()": FunctionFragment;
        "transferOwnership(address)": FunctionFragment;
        "updateDataFeedValues(uint256,uint256)": FunctionFragment;
        "validateTimestamp(uint256)": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "addDataFeedIdAndUpdateValues" | "aggregateValues" | "getAllMockAuthorised" | "getAllMockExceptLastOneAuthorised" | "getAuthorisedMockSignerIndex" | "getAuthorisedSignerIndex" | "getDataFeedsIds" | "getLastRound" | "getLastRoundParams" | "getLastUpdateTimestamp" | "getUniqueSignersThreshold" | "getValueForDataFeed" | "getValueForDataFeedAndLastRoundParams" | "getValuesForDataFeeds" | "lastRound" | "lastUpdateTimestampMilliseconds" | "owner" | "renounceOwnership" | "transferOwnership" | "updateDataFeedValues" | "validateTimestamp"): FunctionFragment;
    encodeFunctionData(functionFragment: "addDataFeedIdAndUpdateValues", values: [PromiseOrValue<BytesLike>, PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "aggregateValues", values: [PromiseOrValue<BigNumberish>[]]): string;
    encodeFunctionData(functionFragment: "getAllMockAuthorised", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAllMockExceptLastOneAuthorised", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAuthorisedMockSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getAuthorisedSignerIndex", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "getDataFeedsIds", values?: undefined): string;
    encodeFunctionData(functionFragment: "getLastRound", values?: undefined): string;
    encodeFunctionData(functionFragment: "getLastRoundParams", values?: undefined): string;
    encodeFunctionData(functionFragment: "getLastUpdateTimestamp", values?: undefined): string;
    encodeFunctionData(functionFragment: "getUniqueSignersThreshold", values?: undefined): string;
    encodeFunctionData(functionFragment: "getValueForDataFeed", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "getValueForDataFeedAndLastRoundParams", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "getValuesForDataFeeds", values: [PromiseOrValue<BytesLike>[]]): string;
    encodeFunctionData(functionFragment: "lastRound", values?: undefined): string;
    encodeFunctionData(functionFragment: "lastUpdateTimestampMilliseconds", values?: undefined): string;
    encodeFunctionData(functionFragment: "owner", values?: undefined): string;
    encodeFunctionData(functionFragment: "renounceOwnership", values?: undefined): string;
    encodeFunctionData(functionFragment: "transferOwnership", values: [PromiseOrValue<string>]): string;
    encodeFunctionData(functionFragment: "updateDataFeedValues", values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "validateTimestamp", values: [PromiseOrValue<BigNumberish>]): string;
    decodeFunctionResult(functionFragment: "addDataFeedIdAndUpdateValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "aggregateValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAllMockAuthorised", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAllMockExceptLastOneAuthorised", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedMockSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getAuthorisedSignerIndex", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getDataFeedsIds", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getLastRound", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getLastRoundParams", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getLastUpdateTimestamp", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getUniqueSignersThreshold", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getValueForDataFeed", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getValueForDataFeedAndLastRoundParams", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getValuesForDataFeeds", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "lastRound", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "lastUpdateTimestampMilliseconds", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "renounceOwnership", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "transferOwnership", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "updateDataFeedValues", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "validateTimestamp", data: BytesLike): Result;
    events: {
        "OwnershipTransferred(address,address)": EventFragment;
    };
    getEvent(nameOrSignatureOrTopic: "OwnershipTransferred"): EventFragment;
}
export interface OwnershipTransferredEventObject {
    previousOwner: string;
    newOwner: string;
}
export declare type OwnershipTransferredEvent = TypedEvent<[
    string,
    string
], OwnershipTransferredEventObject>;
export declare type OwnershipTransferredEventFilter = TypedEventFilter<OwnershipTransferredEvent>;
export interface PriceFeedsManagerMock extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: PriceFeedsManagerMockInterface;
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
        addDataFeedIdAndUpdateValues(newDataFeedId: PromiseOrValue<BytesLike>, proposedTimestamp: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<[BigNumber]>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<[number]>;
        getDataFeedsIds(overrides?: CallOverrides): Promise<[string[]]>;
        getLastRound(overrides?: CallOverrides): Promise<[BigNumber]>;
        getLastRoundParams(overrides?: CallOverrides): Promise<[BigNumber, BigNumber]>;
        getLastUpdateTimestamp(overrides?: CallOverrides): Promise<[BigNumber]>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<[number]>;
        getValueForDataFeed(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<[BigNumber]>;
        getValueForDataFeedAndLastRoundParams(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<[
            BigNumber,
            BigNumber,
            BigNumber
        ] & {
            dataFeedValue: BigNumber;
            lastRoundNumber: BigNumber;
            lastUpdateTimestampInMilliseconds: BigNumber;
        }>;
        getValuesForDataFeeds(requestedDataFeedsIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<[BigNumber[]]>;
        lastRound(overrides?: CallOverrides): Promise<[BigNumber]>;
        lastUpdateTimestampMilliseconds(overrides?: CallOverrides): Promise<[BigNumber]>;
        owner(overrides?: CallOverrides): Promise<[string]>;
        renounceOwnership(overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        transferOwnership(newOwner: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        updateDataFeedValues(proposedRound: PromiseOrValue<BigNumberish>, proposedTimestamp: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[void]>;
    };
    addDataFeedIdAndUpdateValues(newDataFeedId: PromiseOrValue<BytesLike>, proposedTimestamp: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
    getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
    getDataFeedsIds(overrides?: CallOverrides): Promise<string[]>;
    getLastRound(overrides?: CallOverrides): Promise<BigNumber>;
    getLastRoundParams(overrides?: CallOverrides): Promise<[BigNumber, BigNumber]>;
    getLastUpdateTimestamp(overrides?: CallOverrides): Promise<BigNumber>;
    getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
    getValueForDataFeed(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
    getValueForDataFeedAndLastRoundParams(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<[
        BigNumber,
        BigNumber,
        BigNumber
    ] & {
        dataFeedValue: BigNumber;
        lastRoundNumber: BigNumber;
        lastUpdateTimestampInMilliseconds: BigNumber;
    }>;
    getValuesForDataFeeds(requestedDataFeedsIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<BigNumber[]>;
    lastRound(overrides?: CallOverrides): Promise<BigNumber>;
    lastUpdateTimestampMilliseconds(overrides?: CallOverrides): Promise<BigNumber>;
    owner(overrides?: CallOverrides): Promise<string>;
    renounceOwnership(overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    transferOwnership(newOwner: PromiseOrValue<string>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    updateDataFeedValues(proposedRound: PromiseOrValue<BigNumberish>, proposedTimestamp: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    callStatic: {
        addDataFeedIdAndUpdateValues(newDataFeedId: PromiseOrValue<BytesLike>, proposedTimestamp: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<number>;
        getDataFeedsIds(overrides?: CallOverrides): Promise<string[]>;
        getLastRound(overrides?: CallOverrides): Promise<BigNumber>;
        getLastRoundParams(overrides?: CallOverrides): Promise<[BigNumber, BigNumber]>;
        getLastUpdateTimestamp(overrides?: CallOverrides): Promise<BigNumber>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<number>;
        getValueForDataFeed(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        getValueForDataFeedAndLastRoundParams(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<[
            BigNumber,
            BigNumber,
            BigNumber
        ] & {
            dataFeedValue: BigNumber;
            lastRoundNumber: BigNumber;
            lastUpdateTimestampInMilliseconds: BigNumber;
        }>;
        getValuesForDataFeeds(requestedDataFeedsIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<BigNumber[]>;
        lastRound(overrides?: CallOverrides): Promise<BigNumber>;
        lastUpdateTimestampMilliseconds(overrides?: CallOverrides): Promise<BigNumber>;
        owner(overrides?: CallOverrides): Promise<string>;
        renounceOwnership(overrides?: CallOverrides): Promise<void>;
        transferOwnership(newOwner: PromiseOrValue<string>, overrides?: CallOverrides): Promise<void>;
        updateDataFeedValues(proposedRound: PromiseOrValue<BigNumberish>, proposedTimestamp: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    };
    filters: {
        "OwnershipTransferred(address,address)"(previousOwner?: PromiseOrValue<string> | null, newOwner?: PromiseOrValue<string> | null): OwnershipTransferredEventFilter;
        OwnershipTransferred(previousOwner?: PromiseOrValue<string> | null, newOwner?: PromiseOrValue<string> | null): OwnershipTransferredEventFilter;
    };
    estimateGas: {
        addDataFeedIdAndUpdateValues(newDataFeedId: PromiseOrValue<BytesLike>, proposedTimestamp: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<BigNumber>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<BigNumber>;
        getDataFeedsIds(overrides?: CallOverrides): Promise<BigNumber>;
        getLastRound(overrides?: CallOverrides): Promise<BigNumber>;
        getLastRoundParams(overrides?: CallOverrides): Promise<BigNumber>;
        getLastUpdateTimestamp(overrides?: CallOverrides): Promise<BigNumber>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<BigNumber>;
        getValueForDataFeed(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        getValueForDataFeedAndLastRoundParams(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        getValuesForDataFeeds(requestedDataFeedsIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<BigNumber>;
        lastRound(overrides?: CallOverrides): Promise<BigNumber>;
        lastUpdateTimestampMilliseconds(overrides?: CallOverrides): Promise<BigNumber>;
        owner(overrides?: CallOverrides): Promise<BigNumber>;
        renounceOwnership(overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        transferOwnership(newOwner: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        updateDataFeedValues(proposedRound: PromiseOrValue<BigNumberish>, proposedTimestamp: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
    };
    populateTransaction: {
        addDataFeedIdAndUpdateValues(newDataFeedId: PromiseOrValue<BytesLike>, proposedTimestamp: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        aggregateValues(values: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAllMockAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAllMockExceptLastOneAuthorised(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAuthorisedMockSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getAuthorisedSignerIndex(signerAddress: PromiseOrValue<string>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getDataFeedsIds(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getLastRound(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getLastRoundParams(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getLastUpdateTimestamp(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getUniqueSignersThreshold(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getValueForDataFeed(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getValueForDataFeedAndLastRoundParams(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getValuesForDataFeeds(requestedDataFeedsIds: PromiseOrValue<BytesLike>[], overrides?: CallOverrides): Promise<PopulatedTransaction>;
        lastRound(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        lastUpdateTimestampMilliseconds(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        owner(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        renounceOwnership(overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        transferOwnership(newOwner: PromiseOrValue<string>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        updateDataFeedValues(proposedRound: PromiseOrValue<BigNumberish>, proposedTimestamp: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        validateTimestamp(receivedTimestampMilliseconds: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=PriceFeedsManagerMock.d.ts.map