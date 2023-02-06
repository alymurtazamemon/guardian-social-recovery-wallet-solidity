import { BigNumber, ContractTransaction } from "ethers";
import { ethers } from "hardhat";
import { Guardian } from "../typechain-types";

let guardian: Guardian;

async function main(): Promise<void> {
    const [deployer, account2, account3, account4] = await ethers.getSigners();

    guardian = await ethers.getContract("Guardian", deployer);

    await addGuardian(account3.address);
}

async function addGuardian(address: string) {
    const tx: ContractTransaction = await guardian.addGuardian(address);

    await tx.wait(1);

    console.log(`Guardian with address ${address} Added!`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.log(error);
        process.exit(1);
    });
