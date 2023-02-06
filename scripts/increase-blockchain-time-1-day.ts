import { BigNumber } from "ethers";
import { ethers, network } from "hardhat";
import { Guardian } from "../typechain-types";

async function increaseBlockchainTime1Day(): Promise<void> {
    const [deployer] = await ethers.getSigners();

    const guardian: Guardian = await ethers.getContract("Guardian", deployer);

    const delay: BigNumber = await guardian.getAddGuardianDelay();

    await network.provider.send("evm_increaseTime", [delay.toNumber()]);

    console.log(`Blockchain time increase 1 day`);
}

increaseBlockchainTime1Day()
    .then(() => process.exit(0))
    .catch((error) => {
        console.log(error);
        process.exit(1);
    });
