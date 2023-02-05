import { BigNumber, ContractTransaction } from "ethers";
import { ethers } from "hardhat";

async function depositFunds(): Promise<void> {
    const oneEther: BigNumber = ethers.utils.parseEther("1");

    const [deployer] = await ethers.getSigners();

    const guardian = await ethers.getContract("Guardian", deployer);

    const tx: ContractTransaction = await deployer.sendTransaction({
        to: guardian.address,
        data: "0x",
        value: oneEther,
    });

    await tx.wait(1);

    console.log(`Deposited ${oneEther} Ethers`);
}

depositFunds()
    .then(() => process.exit(0))
    .catch((error) => {
        console.log(error);
        process.exit(1);
    });
