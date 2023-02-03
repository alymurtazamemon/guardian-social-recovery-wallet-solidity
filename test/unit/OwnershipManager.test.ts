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

          async function addGuardian(address: string) {
              const addTime: BigNumber =
                  await guardian.getLastGuardianAddTime();

              const delayTime: BigNumber = await guardian.getAddGuardianDelay();

              await network.provider.send("evm_increaseTime", [
                  addTime.toNumber() + delayTime.toNumber(),
              ]);

              const tx: ContractTransaction = await guardian.addGuardian(
                  address
              );

              await tx.wait(1);
          }

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

              describe("requestToUpdateOwner - After Adding Guardians", () => {
                  beforeEach(async () => {
                      const [_, account2, account3, account4, account5] =
                          await ethers.getSigners();

                      const newGuardians: string[] = [
                          account2.address,
                          account3.address,
                          account4.address,
                      ];

                      for (let i = 0; i < newGuardians.length; i++) {
                          await addGuardian(newGuardians[i]);
                      }
                  });

                  it("should revert if address is not a guardian.", async () => {
                      const [_, account2, account3, account4, account5] =
                          await ethers.getSigners();

                      await expect(
                          guardian
                              .connect(account5)
                              .requestToUpdateOwner(account5.address)
                      )
                          .to.be.revertedWithCustomError(
                              guardian,
                              "Error__AddressNotFoundAsGuardian"
                          )
                          .withArgs("OwnershipManager", account5.address);
                  });
              });
          });
      });
