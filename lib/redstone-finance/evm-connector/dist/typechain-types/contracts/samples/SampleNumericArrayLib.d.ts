import type { BaseContract, BigNumber, BigNumberish, BytesLike, CallOverrides, ContractTransaction, Overrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../common";
export interface SampleNumericArrayLibInterface extends utils.Interface {
    functions: {
        "cachedMedian()": FunctionFragment;
        "getCachedArray()": FunctionFragment;
        "testArrayUpdatingInStorage(uint256[])": FunctionFragment;
        "testMedianSelection(uint256[])": FunctionFragment;
        "testSortTx(uint256[])": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "cachedMedian" | "getCachedArray" | "testArrayUpdatingInStorage" | "testMedianSelection" | "testSortTx"): FunctionFragment;
    encodeFunctionData(functionFragment: "cachedMedian", values?: undefined): string;
    encodeFunctionData(functionFragment: "getCachedArray", values?: undefined): string;
    encodeFunctionData(functionFragment: "testArrayUpdatingInStorage", values: [PromiseOrValue<BigNumberish>[]]): string;
    encodeFunctionData(functionFragment: "testMedianSelection", values: [PromiseOrValue<BigNumberish>[]]): string;
    encodeFunctionData(functionFragment: "testSortTx", values: [PromiseOrValue<BigNumberish>[]]): string;
    decodeFunctionResult(functionFragment: "cachedMedian", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "getCachedArray", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "testArrayUpdatingInStorage", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "testMedianSelection", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "testSortTx", data: BytesLike): Result;
    events: {};
}
export interface SampleNumericArrayLib extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: SampleNumericArrayLibInterface;
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
        cachedMedian(overrides?: CallOverrides): Promise<[BigNumber]>;
        getCachedArray(overrides?: CallOverrides): Promise<[BigNumber[]]>;
        testArrayUpdatingInStorage(arr: PromiseOrValue<BigNumberish>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        testMedianSelection(arr: PromiseOrValue<BigNumberish>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
        testSortTx(arr: PromiseOrValue<BigNumberish>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<ContractTransaction>;
    };
    cachedMedian(overrides?: CallOverrides): Promise<BigNumber>;
    getCachedArray(overrides?: CallOverrides): Promise<BigNumber[]>;
    testArrayUpdatingInStorage(arr: PromiseOrValue<BigNumberish>[], overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    testMedianSelection(arr: PromiseOrValue<BigNumberish>[], overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    testSortTx(arr: PromiseOrValue<BigNumberish>[], overrides?: Overrides & {
        from?: PromiseOrValue<string>;
    }): Promise<ContractTransaction>;
    callStatic: {
        cachedMedian(overrides?: CallOverrides): Promise<BigNumber>;
        getCachedArray(overrides?: CallOverrides): Promise<BigNumber[]>;
        testArrayUpdatingInStorage(arr: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<void>;
        testMedianSelection(arr: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<void>;
        testSortTx(arr: PromiseOrValue<BigNumberish>[], overrides?: CallOverrides): Promise<void>;
    };
    filters: {};
    estimateGas: {
        cachedMedian(overrides?: CallOverrides): Promise<BigNumber>;
        getCachedArray(overrides?: CallOverrides): Promise<BigNumber>;
        testArrayUpdatingInStorage(arr: PromiseOrValue<BigNumberish>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        testMedianSelection(arr: PromiseOrValue<BigNumberish>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
        testSortTx(arr: PromiseOrValue<BigNumberish>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<BigNumber>;
    };
    populateTransaction: {
        cachedMedian(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        getCachedArray(overrides?: CallOverrides): Promise<PopulatedTransaction>;
        testArrayUpdatingInStorage(arr: PromiseOrValue<BigNumberish>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        testMedianSelection(arr: PromiseOrValue<BigNumberish>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
        testSortTx(arr: PromiseOrValue<BigNumberish>[], overrides?: Overrides & {
            from?: PromiseOrValue<string>;
        }): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=SampleNumericArrayLib.d.ts.map