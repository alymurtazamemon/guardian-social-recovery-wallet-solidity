import { network } from "hardhat";
import { DeployFunction, DeployResult } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { developmentChains } from "../helper-hardhat-config";

const deployGuardian: DeployFunction = async (
    hre: HardhatRuntimeEnvironment
) => {
    const { deploy } = hre.deployments;
    const { deployer } = await hre.getNamedAccounts();
    const chainId = network.config.chainId!;

    const args: any[] = [];

    const guardian: DeployResult = await deploy("Guardian", {
        from: deployer,
        log: true,
        args: args,
        waitConfirmations: developmentChains.includes(network.name) ? 1 : 6,
    });
};

export default deployGuardian;
deployGuardian.tags = ["all", "guardian"];
