import { DeployFunction } from "hardhat-deploy/dist/types";
import fs from "fs";
import { ethers, network } from "hardhat";
import { Guardian, GuardianFactory } from "../typechain-types";

const FRONTEND_CONTRACT_ADDRESSES_FILE_PATH: string =
    "../frontend/src/constants/contractAddresses.json";
const FRONTEND_ABI_FILE_PATH: string = "../frontend/src/constants/abi.json";

const FRONTEND_GUARDIAN_FACTORY_ABI_FILE_PATH: string =
    "../frontend/src/constants/guardianFactoryAbi.json";
const FRONTEND_GUARDIAN_FACTORY_CONTRACT_ADDRESSES_FILE_PATH: string =
    "../frontend/src/constants/guardianFactoryContractAddresses.json";

const updateFrontendFunction: DeployFunction = async () => {
    if (process.env.UPDATE_FRONTEND == "true") {
        console.log("Updating the frontend...");
        await updateContractAddresses();
        await updateAbi();
        console.log("Done!");
    }
};

async function updateAbi() {
    const guardian = await ethers.getContract("Guardian");
    const guardianFactory: GuardianFactory = await ethers.getContract(
        "GuardianFactory"
    );

    fs.writeFileSync(
        FRONTEND_ABI_FILE_PATH,
        JSON.parse(
            JSON.stringify(
                guardian.interface.format(ethers.utils.FormatTypes.json)
            )
        )
    );

    fs.writeFileSync(
        FRONTEND_GUARDIAN_FACTORY_ABI_FILE_PATH,
        JSON.parse(
            JSON.stringify(
                guardianFactory.interface.format(ethers.utils.FormatTypes.json)
            )
        )
    );
}

async function updateContractAddresses() {
    // * get the contract.
    const guardian: Guardian = await ethers.getContract("Guardian");
    const guardianFactory: GuardianFactory = await ethers.getContract(
        "GuardianFactory"
    );

    // * read the contracts array file from frontend (check the location twice).
    const contractAddresses = JSON.parse(
        fs.readFileSync(FRONTEND_CONTRACT_ADDRESSES_FILE_PATH, "utf-8")
    );
    const guardianFactoryContractAddresses = JSON.parse(
        fs.readFileSync(
            FRONTEND_GUARDIAN_FACTORY_CONTRACT_ADDRESSES_FILE_PATH,
            "utf-8"
        )
    );

    // * read the chainId.
    const chainId: string | undefined = network.config.chainId?.toString();

    // * if chainId is undefined show the message.
    if (chainId != undefined) {
        // * check whether the chainId already exist in array or not.
        if (chainId in contractAddresses) {
            // * if yes then check whether the array already contains the address or not.
            if (
                !contractAddresses[network.config.chainId!].includes(
                    guardian.address
                )
            ) {
                // * if not then push this new address to existing addresses of contract.
                contractAddresses[network.config.chainId!].push(
                    guardian.address
                );
            }
        } else {
            // * if not then create the new array of contract addresses.
            contractAddresses[network.config.chainId!] = [guardian.address];
        }
        fs.writeFileSync(
            FRONTEND_CONTRACT_ADDRESSES_FILE_PATH,
            JSON.stringify(contractAddresses)
        );

        // * check whether the chainId already exist in array or not.
        if (chainId in guardianFactoryContractAddresses) {
            // * if yes then check whether the array already contains the address or not.
            if (
                !guardianFactoryContractAddresses[
                    network.config.chainId!
                ].includes(guardianFactory.address)
            ) {
                // * if not then push this new address to existing addresses of contract.
                guardianFactoryContractAddresses[network.config.chainId!].push(
                    guardianFactory.address
                );
            }
        } else {
            // * if not then create the new array of contract addresses.
            guardianFactoryContractAddresses[network.config.chainId!] = [
                guardianFactory.address,
            ];
        }
        fs.writeFileSync(
            FRONTEND_GUARDIAN_FACTORY_CONTRACT_ADDRESSES_FILE_PATH,
            JSON.stringify(guardianFactoryContractAddresses)
        );
    } else {
        console.log(
            `ChainId is undefined, here is the value of it: ${chainId}`
        );
    }
}

export default updateFrontendFunction;
updateFrontendFunction.tags = ["all", "frontend"];
