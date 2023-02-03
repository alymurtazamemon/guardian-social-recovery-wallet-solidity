import { deployments, ethers, getNamedAccounts, network } from "hardhat";
import { developmentChains } from "../../helper-hardhat-config";
import { Guardian } from "../../typechain-types";
import { expect } from "chai";
import { BigNumber, ContractTransaction } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// * if the newwork will be hardhat or localhost then these tests will be run.
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("GuardiansManager Contract - Unit Tests", () => {
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

          async function addGuardian(account: SignerWithAddress) {
              const addTime: BigNumber =
                  await guardian.getLastGuardianAddTime();

              const delayTime: BigNumber = await guardian.getAddGuardianDelay();

              await network.provider.send("evm_increaseTime", [
                  addTime.toNumber() + delayTime.toNumber(),
              ]);

              const tx: ContractTransaction = await guardian.addGuardian(
                  account.address
              );

              await tx.wait(1);
          }

          describe("addGuardian", () => {
              it("should revert if called by address which is not an owner.", async () => {
                  const [_, account2, account3] = await ethers.getSigners();

                  await expect(
                      guardian.connect(account2).addGuardian(account3.address)
                  ).to.be.revertedWith("Ownable: caller is not the owner");
              });

              it("should add new guardian.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  await addGuardian(account2);

                  const guardians: string[] = await guardian.getGuardians();
                  expect(guardians.length).to.be.equal(1);

                  const requiredConfirmations: BigNumber =
                      await guardian.getRequiredConfirmations();
                  expect(requiredConfirmations).to.be.equal(1);
              });
          });

          describe("changeGuardian", () => {
              it("should revert if called by an address which is not an owner.", async () => {
                  const [_, account2, account3, account4] =
                      await ethers.getSigners();

                  await expect(
                      guardian
                          .connect(account2)
                          .changeGuardian(account3.address, account4.address)
                  ).to.be.revertedWith("Ownable: caller is not the owner");
              });

              it("should revert if delay time is not passed before changing guardian.", async () => {
                  const [_, account2, account3] = await ethers.getSigners();

                  await expect(
                      guardian.changeGuardian(
                          account2.address,
                          account3.address
                      )
                  ).to.be.revertedWithCustomError(
                      guardian,
                      "Error__CanOnlyChangeAfterDelayPeriod"
                  );
              });

              describe("changeGuardian - After Delay", () => {
                  beforeEach(async () => {
                      const changeTime: BigNumber =
                          await guardian.getLastGuardianChangeTime();

                      const delayTime: BigNumber =
                          await guardian.getChangeGuardianDelay();

                      await network.provider.send("evm_increaseTime", [
                          changeTime.toNumber() + delayTime.toNumber(),
                      ]);
                  });

                  it("should revert if the `from` address does not exist.", async () => {
                      const [_, account2, account3] = await ethers.getSigners();

                      await expect(
                          guardian.changeGuardian(
                              account2.address,
                              account3.address
                          )
                      ).to.be.revertedWithCustomError(
                          guardian,
                          "Error__GuardianDoesNotExist"
                      );
                  });

                  it("should change the guardian.", async () => {
                      const [_, account2, account3, account4, account5] =
                          await ethers.getSigners();

                      const newGuardians: string[] = [
                          account2.address,
                          account3.address,
                          account4.address,
                      ];

                      for (let i = 0; i < newGuardians.length; i++) {
                          const addTime: BigNumber =
                              await guardian.getLastGuardianAddTime();

                          const delayTime: BigNumber =
                              await guardian.getAddGuardianDelay();

                          await network.provider.send("evm_increaseTime", [
                              addTime.toNumber() + delayTime.toNumber(),
                          ]);

                          const tx: ContractTransaction =
                              await guardian.addGuardian(newGuardians[i]);

                          await tx.wait(1);
                      }

                      const guardians: string[] = await guardian.getGuardians();

                      expect(guardians[0]).to.be.equal(newGuardians[0]);

                      const changeTime: BigNumber =
                          await guardian.getLastGuardianChangeTime();

                      const tx2: ContractTransaction =
                          await guardian.changeGuardian(
                              account2.address,
                              account5.address
                          );

                      await tx2.wait(1);

                      const updatedGuardians: string[] =
                          await guardian.getGuardians();

                      expect(updatedGuardians[0]).to.be.equal(account5.address);

                      const updatedChangeTime: BigNumber =
                          await guardian.getLastGuardianChangeTime();

                      expect(changeTime).to.not.be.equal(updatedChangeTime);
                  });

                  it("should not change another guardian before delay time.", async () => {
                      const [_, account2, account3, account4, account5] =
                          await ethers.getSigners();

                      const newGuardians: string[] = [
                          account2.address,
                          account3.address,
                          account4.address,
                      ];

                      for (let i = 0; i < newGuardians.length; i++) {
                          const addTime: BigNumber =
                              await guardian.getLastGuardianAddTime();

                          const delayTime: BigNumber =
                              await guardian.getAddGuardianDelay();

                          await network.provider.send("evm_increaseTime", [
                              addTime.toNumber() + delayTime.toNumber(),
                          ]);

                          const tx: ContractTransaction =
                              await guardian.addGuardian(newGuardians[i]);

                          await tx.wait(1);
                      }

                      const guardians: string[] = await guardian.getGuardians();

                      expect(guardians[0]).to.be.equal(newGuardians[0]);

                      const changeTime: BigNumber =
                          await guardian.getLastGuardianChangeTime();

                      const tx2: ContractTransaction =
                          await guardian.changeGuardian(
                              account2.address,
                              account5.address
                          );

                      await tx2.wait(1);

                      const updatedGuardians: string[] =
                          await guardian.getGuardians();

                      expect(updatedGuardians[0]).to.be.equal(account5.address);

                      const updatedChangeTime: BigNumber =
                          await guardian.getLastGuardianChangeTime();

                      expect(changeTime).to.not.be.equal(updatedChangeTime);

                      await expect(
                          guardian.changeGuardian(
                              account5.address,
                              account2.address
                          )
                      ).to.be.revertedWithCustomError(
                          guardian,
                          "Error__CanOnlyChangeAfterDelayPeriod"
                      );
                  });
              });
          });

          describe("removeGuardian", () => {
              it("should revert if called by an address which is not an owner.", async () => {
                  const [_, account2, account3] = await ethers.getSigners();

                  await expect(
                      guardian
                          .connect(account2)
                          .removeGuardian(account3.address)
                  ).to.be.revertedWith("Ownable: caller is not the owner");
              });

              it("should revert if delay time is not passed before removing a guardian.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  await expect(
                      guardian.removeGuardian(account2.address)
                  ).to.be.revertedWithCustomError(
                      guardian,
                      "Error__CanOnlyRemoveAfterDelayPeriod"
                  );
              });

              it("should revert if there is no guardians to remove.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  const removalTime: BigNumber =
                      await guardian.getLastGuardianRemovalTime();
                  const delayTime: BigNumber =
                      await guardian.getRemoveGuardianDelay();

                  await network.provider.send("evm_increaseTime", [
                      removalTime.toNumber() + delayTime.toNumber(),
                  ]);

                  await expect(
                      guardian.removeGuardian(account2.address)
                  ).to.be.revertedWithCustomError(
                      guardian,
                      "Error__GuardiansListIsEmpty"
                  );
              });

              describe("removeGuardian - After Adding Guardians & Delay", () => {
                  beforeEach(async () => {
                      const [_, account2, account3, account4] =
                          await ethers.getSigners();

                      const newGuardians: string[] = [
                          account2.address,
                          account3.address,
                          account4.address,
                      ];

                      for (let i = 0; i < newGuardians.length; i++) {
                          const addTime: BigNumber =
                              await guardian.getLastGuardianAddTime();

                          const delayTime: BigNumber =
                              await guardian.getAddGuardianDelay();

                          await network.provider.send("evm_increaseTime", [
                              addTime.toNumber() + delayTime.toNumber(),
                          ]);

                          const tx: ContractTransaction =
                              await guardian.addGuardian(newGuardians[i]);

                          await tx.wait(1);
                      }

                      const removalTime: BigNumber =
                          await guardian.getLastGuardianRemovalTime();

                      const delayTime: BigNumber =
                          await guardian.getRemoveGuardianDelay();

                      await network.provider.send("evm_increaseTime", [
                          removalTime.toNumber() + delayTime.toNumber(),
                      ]);
                  });

                  it("should revert if the `guardian` address does not exist.", async () => {
                      const [_, account2, account3, account4, account5] =
                          await ethers.getSigners();

                      await expect(
                          guardian.removeGuardian(account5.address)
                      ).to.be.revertedWithCustomError(
                          guardian,
                          "Error__GuardianDoesNotExist"
                      );
                  });

                  it("should remove a guardian.", async () => {
                      const [_, account2] = await ethers.getSigners();

                      const tx: ContractTransaction =
                          await guardian.removeGuardian(account2.address);

                      await tx.wait(1);

                      const guardians: string[] = await guardian.getGuardians();
                      expect(guardians.length).to.be.equal(2);
                      expect(guardians.includes(account2.address)).to.be.false;
                  });

                  it("should not remove another guardian before delay time.", async () => {
                      const [_, account2, account3] = await ethers.getSigners();

                      const tx: ContractTransaction =
                          await guardian.removeGuardian(account2.address);

                      await tx.wait(1);

                      const guardians: string[] = await guardian.getGuardians();
                      expect(guardians.length).to.be.equal(2);
                      expect(guardians.includes(account2.address)).to.be.false;

                      await expect(
                          guardian.removeGuardian(account3.address)
                      ).to.be.revertedWithCustomError(
                          guardian,
                          "Error__CanOnlyRemoveAfterDelayPeriod"
                      );
                  });
              });
          });
      });
