import { BigNumber, ContractTransaction } from "ethers";
import { ethers } from "hardhat";
import { Guardian } from "../typechain-types";

async function addGuardian(): Promise<void> {
    const [deployer, account2] = await ethers.getSigners();

    const guardian: Guardian = await ethers.getContract("Guardian", deployer);

    const tx: ContractTransaction = await guardian.addGuardian(
        account2.address
    );

    await tx.wait(1);

    console.log(`Guardian with address ${account2.address} Added!`);
}

addGuardian()
    .then(() => process.exit(0))
    .catch((error) => {
        console.log(error);
        process.exit(1);
    });
