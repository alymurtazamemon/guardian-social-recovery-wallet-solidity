import { network } from "hardhat";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const DECIMALS = "8";
const INITIAL_PRICE = "166500000000"; // 1665 USD

const deployMocks: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();
    const chainId = network.config.chainId!;

    if (chainId == 31337) {
        console.log(`Running on Local Network. Deploying Mocks...`);
        await deploy("MockV3Aggregator", {
            contract: "MockV3Aggregator",
            from: deployer,
            log: true,
            args: [DECIMALS, INITIAL_PRICE],
        });
        console.log(`Mocks deployed!`);
    }
};

export default deployMocks;
deployMocks.tags = ["all", "mocks"];
