import type { BaseContract, BigNumber, BigNumberish, BytesLike, CallOverrides, ContractTransaction, Overrides, PayableOverrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../common";
export interface SampleProxyConnectorInterface extends utils.Interface {
    functions: {
        "checkOracleValue(bytes32,uint256)": FunctionFragment;
        "checkOracleValueLongEncodedFunction(bytes32,uint256)": FunctionFragment;
        "getOracleValueUsingProxy(bytes32)": FunctionFragment;
        "proxyEmptyError()": FunctionFragment;
        "proxyTestStringError()": FunctionFragment;
        "requireValueForward()": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "checkOracleValue" | "checkOracleValueLongEncodedFunction" | "getOracleValueUsingProxy" | "proxyEmptyError" | "proxyTestStringError" | "requireValueForward"): FunctionFragment;
    encodeFunctionData(functionFragment: "checkOracleValue", values: [PromiseOrValue<BytesLike>, PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "checkOracleValueLongEncodedFunction", values: [PromiseOrValue<BytesLike>, PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "getOracleValueUsingProxy", values: [PromiseOrValue<BytesLike>]): string;
    encodeFunctionData(functionFragment: "proxyEmptyError", values?: undefined): string;
    encodeFunctionData(functionFragment: "proxyTestStringError", values?: undefined): string;
    encodeFunctionData(functionFragment: "requireValueForward", values?: undefined): string;
    decodeFunctionResult(functionFragment: "checkOracleValue", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "checkOracleValueLongEncodedFunction", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getOracleValueUsingProxy", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "proxyEmptyError", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "proxyTestStringError", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "requireValueForward", data: BytesLike): Result;
    events: {};
}
export interface SampleProxyConnector extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: SampleProxyConnectorInterface;
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
        checkOracleValue(dataFeedId: PromiseOrValue<BytesLike>, expectedValue: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[void]>;
        checkOracleValueLongEncodedFunction(asset: PromiseOrValue<BytesLike>, price: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        getOracleValueUsingProxy(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<[BigNumber]>;
        proxyEmptyError(overrides?: CallOverrides): Promise<[void]>;
        proxyTestStringError(overrides?: CallOverrides): Promise<[void]>;
        requireValueForward(overrides?: PayableOverrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
    };
    checkOracleValue(dataFeedId: PromiseOrValue<BytesLike>, expectedValue: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
    checkOracleValueLongEncodedFunction(asset: PromiseOrValue<BytesLike>, price: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    getOracleValueUsingProxy(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
    proxyEmptyError(overrides?: CallOverrides): Promise<void>;
    proxyTestStringError(overrides?: CallOverrides): Promise<void>;
    requireValueForward(overrides?: PayableOverrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    callStatic: {
        checkOracleValue(dataFeedId: PromiseOrValue<BytesLike>, expectedValue: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        checkOracleValueLongEncodedFunction(asset: PromiseOrValue<BytesLike>, price: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<void>;
        getOracleValueUsingProxy(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        proxyEmptyError(overrides?: CallOverrides): Promise<void>;
        proxyTestStringError(overrides?: CallOverrides): Promise<void>;
        requireValueForward(overrides?: CallOverrides): Promise<void>;
    };
    filters: {};
    estimateGas: {
        checkOracleValue(dataFeedId: PromiseOrValue<BytesLike>, expectedValue: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
        checkOracleValueLongEncodedFunction(asset: PromiseOrValue<BytesLike>, price: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        getOracleValueUsingProxy(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<BigNumber>;
        proxyEmptyError(overrides?: CallOverrides): Promise<BigNumber>;
        proxyTestStringError(overrides?: CallOverrides): Promise<BigNumber>;
        requireValueForward(overrides?: PayableOverrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
    };
    populateTransaction: {
        checkOracleValue(dataFeedId: PromiseOrValue<BytesLike>, expectedValue: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        checkOracleValueLongEncodedFunction(asset: PromiseOrValue<BytesLike>, price: PromiseOrValue<BigNumberish>, overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        getOracleValueUsingProxy(dataFeedId: PromiseOrValue<BytesLike>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        proxyEmptyError(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        proxyTestStringError(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        requireValueForward(overrides?: PayableOverrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=SampleProxyConnector.d.ts.map