import { deployments, ethers, getNamedAccounts, network } from "hardhat";
import { developmentChains } from "../../helper-hardhat-config";
import { Guardian } from "../../typechain-types";
import { expect } from "chai";
import { BigNumber, ContractTransaction } from "ethers";

// * if the newwork will be hardhat or localhost then these tests will be run.
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("OwnershipManager Contract - Unit Tests", () => {
          let deployer: string;
          let guardian: Guardian;
          const oneEther: BigNumber = ethers.utils.parseEther("1");

          beforeEach(async () => {
              if (!developmentChains.includes(network.name)) {
                  throw "You need to be on a development chain to run tests";
              }

              deployer = (await getNamedAccounts()).deployer;
              await deployments.fixture(["all"]);

              guardian = await ethers.getContract("Guardian", deployer);
          });

          describe("requestToUpdateOwner", () => {
              it("should revert if given address is same as previous owner.", async () => {
                  const [deployer] = await ethers.getSigners();

                  await expect(guardian.requestToUpdateOwner(deployer.address))
                      .to.be.revertedWithCustomError(
                          guardian,
                          "Error__AddressAlreadyAnOwner"
                      )
                      .withArgs("OwnershipManager", deployer.address);
              });

              it("should revert if guardians list is empty.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  await expect(
                      guardian.requestToUpdateOwner(account2.address)
                  ).to.be.revertedWithCustomError(
                      guardian,
                      "Error__GuardiansListIsEmpty"
                  );
              });
          });
      });
