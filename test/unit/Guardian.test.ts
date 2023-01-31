import { network } from "hardhat";
import { developmentChains } from "../../helper-hardhat-config";

// * if the newwork will be hardhat or localhost then these tests will be run.
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Guardian Contract - Unit Tests", () => {});
