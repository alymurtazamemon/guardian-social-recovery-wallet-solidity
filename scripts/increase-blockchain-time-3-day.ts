import { BigNumber } from "ethers";
import { ethers, network } from "hardhat";
import { Guardian } from "../typechain-types";

async function increaseBlockchainTime3Day(): Promise<void> {
    const [deployer] = await ethers.getSigners();

    const guardian: Guardian = await ethers.getContract("Guardian", deployer);

    const delay: BigNumber = await guardian.getChangeGuardianDelay();

    await network.provider.send("evm_increaseTime", [delay.toNumber()]);

    console.log(`Blockchain time increase 3 days`);
}

increaseBlockchainTime3Day()
    .then(() => process.exit(0))
    .catch((error) => {
        console.log(error);
        process.exit(1);
    });
