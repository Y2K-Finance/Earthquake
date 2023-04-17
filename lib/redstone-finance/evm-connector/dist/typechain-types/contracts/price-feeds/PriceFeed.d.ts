import type { BaseContract, BigNumber, BigNumberish, BytesLike, CallOverrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../common";
export interface PriceFeedInterface extends utils.Interface {
    functions: {
        "dataFeedId()": FunctionFragment;
        "decimals()": FunctionFragment;
        "description()": FunctionFragment;
        "descriptionText()": FunctionFragment;
        "getDataFeedId()": FunctionFragment;
        "getRoundData(uint80)": FunctionFragment;
        "latestRoundData()": FunctionFragment;
        "version()": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "dataFeedId" | "decimals" | "description" | "descriptionText" | "getDataFeedId" | "getRoundData" | "latestRoundData" | "version"): FunctionFragment;
    encodeFunctionData(functionFragment: "dataFeedId", values?: undefined): string;
    encodeFunctionData(functionFragment: "decimals", values?: undefined): string;
    encodeFunctionData(functionFragment: "description", values?: undefined): string;
    encodeFunctionData(functionFragment: "descriptionText", values?: undefined): string;
    encodeFunctionData(functionFragment: "getDataFeedId", values?: undefined): string;
    encodeFunctionData(functionFragment: "getRoundData", values: [PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "latestRoundData", values?: undefined): string;
    encodeFunctionData(functionFragment: "version", values?: undefined): string;
    decodeFunctionResult(functionFragment: "dataFeedId", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "decimals", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "description", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "descriptionText", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getDataFeedId", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getRoundData", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "latestRoundData", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "version", data: BytesLike): Result;
    events: {};
}
export interface PriceFeed extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: PriceFeedInterface;
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
        dataFeedId(overrides?: CallOverrides): Promise<[string]>;
        decimals(overrides?: CallOverrides): Promise<[number]>;
        description(overrides?: CallOverrides): Promise<[string]>;
        descriptionText(overrides?: CallOverrides): Promise<[string]>;
        getDataFeedId(overrides?: CallOverrides): Promise<[string]>;
        getRoundData(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[BigNumber, BigNumber, BigNumber, BigNumber, BigNumber]>;
        latestRoundData(overrides?: CallOverrides): Promise<[
            BigNumber,
            BigNumber,
            BigNumber,
            BigNumber,
            BigNumber
        ] & {
            roundId: BigNumber;
            answer: BigNumber;
            startedAt: BigNumber;
            updatedAt: BigNumber;
            answeredInRound: BigNumber;
        }>;
        version(overrides?: CallOverrides): Promise<[BigNumber]>;
    };
    dataFeedId(overrides?: CallOverrides): Promise<string>;
    decimals(overrides?: CallOverrides): Promise<number>;
    description(overrides?: CallOverrides): Promise<string>;
    descriptionText(overrides?: CallOverrides): Promise<string>;
    getDataFeedId(overrides?: CallOverrides): Promise<string>;
    getRoundData(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[BigNumber, BigNumber, BigNumber, BigNumber, BigNumber]>;
    latestRoundData(overrides?: CallOverrides): Promise<[
        BigNumber,
        BigNumber,
        BigNumber,
        BigNumber,
        BigNumber
    ] & {
        roundId: BigNumber;
        answer: BigNumber;
        startedAt: BigNumber;
        updatedAt: BigNumber;
        answeredInRound: BigNumber;
    }>;
    version(overrides?: CallOverrides): Promise<BigNumber>;
    callStatic: {
        dataFeedId(overrides?: CallOverrides): Promise<string>;
        decimals(overrides?: CallOverrides): Promise<number>;
        description(overrides?: CallOverrides): Promise<string>;
        descriptionText(overrides?: CallOverrides): Promise<string>;
        getDataFeedId(overrides?: CallOverrides): Promise<string>;
        getRoundData(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[BigNumber, BigNumber, BigNumber, BigNumber, BigNumber]>;
        latestRoundData(overrides?: CallOverrides): Promise<[
            BigNumber,
            BigNumber,
            BigNumber,
            BigNumber,
            BigNumber
        ] & {
            roundId: BigNumber;
            answer: BigNumber;
            startedAt: BigNumber;
            updatedAt: BigNumber;
            answeredInRound: BigNumber;
        }>;
        version(overrides?: CallOverrides): Promise<BigNumber>;
    };
    filters: {};
    estimateGas: {
        dataFeedId(overrides?: CallOverrides): Promise<BigNumber>;
        decimals(overrides?: CallOverrides): Promise<BigNumber>;
        description(overrides?: CallOverrides): Promise<BigNumber>;
        descriptionText(overrides?: CallOverrides): Promise<BigNumber>;
        getDataFeedId(overrides?: CallOverrides): Promise<BigNumber>;
        getRoundData(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
        latestRoundData(overrides?: CallOverrides): Promise<BigNumber>;
        version(overrides?: CallOverrides): Promise<BigNumber>;
    };
    populateTransaction: {
        dataFeedId(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        decimals(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        description(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        descriptionText(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getDataFeedId(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getRoundData(arg0: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        latestRoundData(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        version(overrides?: CallOverrides): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=PriceFeed.d.ts.map