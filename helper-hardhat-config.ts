export interface networkConfigItem {
    ethUsdPriceFeed?: string;
    blockConfirmations?: number;
}

export interface networkConfigInfo {
    [key: string]: networkConfigItem;
}

export const networkConfig: networkConfigInfo = {
    31337: {
        blockConfirmations: 1,
    },
    5: {
        blockConfirmations: 6,
        ethUsdPriceFeed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    },
};

export const developmentChains: string[] = ["hardhat", "localhost"];
