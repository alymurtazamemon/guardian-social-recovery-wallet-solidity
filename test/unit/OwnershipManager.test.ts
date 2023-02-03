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

                  it("should request to update the owner.", async () => {
                      const [_, account2, account3, account4, account5] =
                          await ethers.getSigners();

                      const isRequested: Boolean =
                          await guardian.getIsOwnerUpdateRequested();

                      expect(isRequested).to.be.false;

                      const tx: ContractTransaction = await guardian
                          .connect(account2)
                          .requestToUpdateOwner(account5.address);

                      await tx.wait(1);

                      const updatedIsRequested: Boolean =
                          await guardian.getIsOwnerUpdateRequested();

                      expect(updatedIsRequested).to.be.true;
                  });
              });
          });

          describe("confirmUpdateOwnerRequest", () => {
              it("should revert if guardians list is empty.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  await expect(
                      guardian.confirmUpdateOwnerRequest()
                  ).to.be.revertedWithCustomError(
                      guardian,
                      "Error__GuardiansListIsEmpty"
                  );
              });

              describe("confirmUpdateOwnerRequest - After Adding Guardians", () => {
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

                  it("should revert if owner update is not requested.", async () => {
                      await expect(
                          guardian.confirmUpdateOwnerRequest()
                      ).to.be.revertedWithCustomError(
                          guardian,
                          "Error__UpdateNotRequested"
                      );
                  });

                  describe("confirmUpdateOwnerRequest - After Request", () => {
                      beforeEach(async () => {
                          const [_, account2, account3, account4, account5] =
                              await ethers.getSigners();

                          const tx: ContractTransaction = await guardian
                              .connect(account2)
                              .requestToUpdateOwner(account5.address);

                          await tx.wait(1);
                      });

                      it("should revert if confirmation time is passed.", async () => {
                          const requestTime: BigNumber =
                              await guardian.getLastOwnerUpdateRequestTime();
                          const confirmationTime: BigNumber =
                              await guardian.getOwnerUpdateConfirmationTime();
                          await network.provider.send("evm_increaseTime", [
                              requestTime.toNumber() +
                                  confirmationTime.toNumber(),
                          ]);

                          await expect(
                              guardian.confirmUpdateOwnerRequest()
                          ).to.be.revertedWithCustomError(
                              guardian,
                              "Error__RequestTimeExpired"
                          );
                      });

                      it("should revert if address is not a guardian.", async () => {
                          const [_, account2, account3, account4, account5] =
                              await ethers.getSigners();

                          await expect(
                              guardian
                                  .connect(account5)
                                  .confirmUpdateOwnerRequest()
                          )
                              .to.be.revertedWithCustomError(
                                  guardian,
                                  "Error__AddressNotFoundAsGuardian"
                              )
                              .withArgs("OwnershipManager", account5.address);
                      });

                      it("should confirm the request to update the owner.", async () => {
                          const [_, account2] = await ethers.getSigners();

                          const confirmationStatus: Boolean =
                              await guardian.getIsOwnershipConfimedByGuardian(
                                  account2.address
                              );

                          expect(confirmationStatus).to.be.false;

                          const numberOfConfirmations: BigNumber =
                              await guardian.getNoOfConfirmations();

                          expect(numberOfConfirmations.toNumber()).to.be.equal(
                              0
                          );

                          const tx: ContractTransaction = await guardian
                              .connect(account2)
                              .confirmUpdateOwnerRequest();

                          await tx.wait(1);

                          const updatedConfirmationStatus: Boolean =
                              await guardian.getIsOwnershipConfimedByGuardian(
                                  account2.address
                              );

                          expect(updatedConfirmationStatus).to.be.true;

                          const updatedNumberOfConfirmations: BigNumber =
                              await guardian.getNoOfConfirmations();

                          expect(
                              updatedNumberOfConfirmations.toNumber()
                          ).to.be.equal(1);
                      });

                      it("should revert if already confirmed by a guardian.", async () => {
                          const [_, account2] = await ethers.getSigners();

                          const tx: ContractTransaction = await guardian
                              .connect(account2)
                              .confirmUpdateOwnerRequest();

                          await tx.wait(1);

                          await expect(
                              guardian
                                  .connect(account2)
                                  .confirmUpdateOwnerRequest()
                          )
                              .to.be.revertedWithCustomError(
                                  guardian,
                                  "Error__AlreadyConfirmedByGuardian"
                              )
                              .withArgs("OwnershipManager", account2.address);
                      });
                  });
              });
          });
      });
