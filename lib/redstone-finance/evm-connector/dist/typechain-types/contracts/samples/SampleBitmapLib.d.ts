import type { BaseContract, BigNumber, BigNumberish, BytesLike, CallOverrides, PopulatedTransaction, Signer, utils } from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type { TypedEventFilter, TypedEvent, TypedListener, OnEvent, PromiseOrValue } from "../../common";
export interface SampleBitmapLibInterface extends utils.Interface {
    functions: {
        "getBitFromBitmap(uint256,uint256)": FunctionFragment;
        "setBitInBitmap(uint256,uint256)": FunctionFragment;
    };
    getFunction(nameOrSignatureOrTopic: "getBitFromBitmap" | "setBitInBitmap"): FunctionFragment;
    encodeFunctionData(functionFragment: "getBitFromBitmap", values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>]): string;
    encodeFunctionData(functionFragment: "setBitInBitmap", values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>]): string;
    decodeFunctionResult(functionFragment: "getBitFromBitmap", data: BytesLike): Result;
    decodeFunctionResult(functionFragment: "setBitInBitmap", data: BytesLike): Result;
    events: {};
}
export interface SampleBitmapLib extends BaseContract {
    connect(signerOrProvider: Signer | Provider | string): this;
    attach(addressOrName: string): this;
    deployed(): Promise<this>;
    interface: SampleBitmapLibInterface;
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
        getBitFromBitmap(bitmap: PromiseOrValue<BigNumberish>, bitIndex: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[boolean]>;
        setBitInBitmap(bitmap: PromiseOrValue<BigNumberish>, bitIndex: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<[BigNumber]>;
    };
    getBitFromBitmap(bitmap: PromiseOrValue<BigNumberish>, bitIndex: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<boolean>;
    setBitInBitmap(bitmap: PromiseOrValue<BigNumberish>, bitIndex: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
    callStatic: {
        getBitFromBitmap(bitmap: PromiseOrValue<BigNumberish>, bitIndex: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<boolean>;
        setBitInBitmap(bitmap: PromiseOrValue<BigNumberish>, bitIndex: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
    };
    filters: {};
    estimateGas: {
        getBitFromBitmap(bitmap: PromiseOrValue<BigNumberish>, bitIndex: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
        setBitInBitmap(bitmap: PromiseOrValue<BigNumberish>, bitIndex: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<BigNumber>;
    };
    populateTransaction: {
        getBitFromBitmap(bitmap: PromiseOrValue<BigNumberish>, bitIndex: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
        setBitInBitmap(bitmap: PromiseOrValue<BigNumberish>, bitIndex: PromiseOrValue<BigNumberish>, overrides?: CallOverrides): Promise<PopulatedTransaction>;
    };
}
//# sourceMappingURL=SampleBitmapLib.d.ts.map