import { deployments, ethers, getNamedAccounts, network } from "hardhat";
import { developmentChains } from "../../helper-hardhat-config";
import { Guardian } from "../../typechain-types";
import { expect } from "chai";
import { BigNumber, ContractTransaction } from "ethers";

// * if the newwork will be hardhat or localhost then these tests will be run.
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Guardian Contract - Unit Tests", () => {
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

          describe("receive", () => {
              it("should deposit user funds.", async () => {
                  const [deployer] = await ethers.getSigners();

                  expect(
                      (
                          await ethers.provider.getBalance(guardian.address)
                      ).toString()
                  ).to.be.equal("0");

                  const tx: ContractTransaction =
                      await deployer.sendTransaction({
                          to: guardian.address,
                          data: "0x",
                          value: oneEther,
                      });

                  await tx.wait(1);

                  expect(
                      (
                          await ethers.provider.getBalance(guardian.address)
                      ).toString()
                  ).to.be.equal(oneEther);
              });
          });

          describe("fallback", () => {
              it("should deposit user funds.", async () => {
                  const [deployer] = await ethers.getSigners();

                  expect(
                      (
                          await ethers.provider.getBalance(guardian.address)
                      ).toString()
                  ).to.be.equal("0");

                  const tx: ContractTransaction =
                      await deployer.sendTransaction({
                          to: guardian.address,
                          data: "0xFFFFFFFF",
                          value: oneEther,
                      });

                  await tx.wait(1);

                  expect(
                      (
                          await ethers.provider.getBalance(guardian.address)
                      ).toString()
                  ).to.be.equal(oneEther);
              });
          });

          describe("send", () => {
              it("should revert if called by address which is not an owner.", async () => {
                  const [_, account2, account3] = await ethers.getSigners();

                  await expect(
                      guardian
                          .connect(account2)
                          .send(account3.address, oneEther)
                  ).to.be.revertedWith("Ownable: caller is not the owner");
              });

              it("should revert if amount is less than or equal to zero.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  await expect(guardian.send(account2.address, 0))
                      .to.be.revertedWithCustomError(
                          guardian,
                          "Guardian__InvalidAmount"
                      )
                      .withArgs(0);
              });

              it("should revert if amount is greater than daily transfer limit.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  await expect(guardian.send(account2.address, oneEther.mul(2)))
                      .to.be.revertedWithCustomError(
                          guardian,
                          "Guardian__DailyTransferLimitExceed"
                      )
                      .withArgs(oneEther.mul(2));
              });

              it("should transfer funds to other address.", async () => {
                  const [deployer, account2] = await ethers.getSigners();

                  const tx: ContractTransaction =
                      await deployer.sendTransaction({
                          to: guardian.address,
                          data: "0x",
                          value: oneEther,
                      });

                  await tx.wait(1);

                  const tx2: ContractTransaction = await guardian.send(
                      account2.address,
                      oneEther
                  );

                  await tx2.wait(1);

                  expect(
                      (
                          await ethers.provider.getBalance(guardian.address)
                      ).toString()
                  ).to.be.equal("0");
                  expect(
                      (
                          await ethers.provider.getBalance(account2.address)
                      ).toString()
                  ).to.be.equal(ethers.utils.parseEther("10001"));
              });

              it("should revert if call function fails.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  // * because contract does not have enough funds the transaction will fail and it should revert.
                  await expect(
                      guardian.send(account2.address, oneEther.mul(1))
                  ).to.be.revertedWithCustomError(
                      guardian,
                      "Guardian__TransactionFailed"
                  );
              });
          });

          describe("sendAll", () => {
              it("should revert if called by address which is not an owner.", async () => {
                  const [_, account2, account3] = await ethers.getSigners();

                  await expect(
                      guardian.connect(account2).sendAll(account3.address)
                  ).to.be.revertedWith("Ownable: caller is not the owner");
              });

              it("should revert if amount is less than or equal to zero.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  await expect(guardian.sendAll(account2.address))
                      .to.be.revertedWithCustomError(
                          guardian,
                          "Guardian__BalanceIsZero"
                      )
                      .withArgs(0);
              });

              it("should revert if amount is greater than daily transfer limit.", async () => {
                  const [deployer, account2] = await ethers.getSigners();

                  const tx: ContractTransaction =
                      await deployer.sendTransaction({
                          to: guardian.address,
                          data: "0x",
                          value: oneEther.mul(2),
                      });

                  await tx.wait(1);

                  await expect(guardian.sendAll(account2.address))
                      .to.be.revertedWithCustomError(
                          guardian,
                          "Guardian__DailyTransferLimitExceed"
                      )
                      .withArgs(oneEther.mul(2));
              });

              it("should transfer all of the funds if less than or equal to daily limit.", async () => {
                  const [deployer, account2] = await ethers.getSigners();

                  const tx: ContractTransaction =
                      await deployer.sendTransaction({
                          to: guardian.address,
                          data: "0x",
                          value: oneEther.mul(1),
                      });

                  await tx.wait(1);

                  const tx2: ContractTransaction = await guardian.sendAll(
                      account2.address
                  );

                  await tx2.wait(1);

                  expect(
                      (
                          await ethers.provider.getBalance(guardian.address)
                      ).toString()
                  ).to.be.equal("0");
                  expect(
                      (
                          await ethers.provider.getBalance(account2.address)
                      ).toString()
                  ).to.be.equal(ethers.utils.parseEther("10001"));
              });
          });

          describe("addGuardians", () => {
              it("should revert if called by address which is not an owner.", async () => {
                  const [_, account2, account3] = await ethers.getSigners();

                  await expect(
                      guardian.connect(account2).addGuardians([])
                  ).to.be.revertedWith("Ownable: caller is not the owner");
              });

              it("should revert if the guardians list is empty.", async () => {
                  await expect(guardian.addGuardians([]))
                      .to.be.revertedWithCustomError(
                          guardian,
                          "Guardian__InvalidGuardiansList"
                      )
                      .withArgs([]);
              });

              it("should add new guardians.", async () => {
                  const [_, account2, account3, account4, account5, account6] =
                      await ethers.getSigners();

                  const newGuardians: string[] = [
                      account2.address,
                      account3.address,
                      account4.address,
                      account5.address,
                      account6.address,
                  ];

                  const tx: ContractTransaction = await guardian.addGuardians(
                      newGuardians
                  );

                  await tx.wait(1);

                  const guardians: string[] = await guardian.getGuardians();
                  expect(guardians.length).to.be.equal(newGuardians.length);

                  const requiredConfirmations: BigNumber =
                      await guardian.getRequiredConfirmations();
                  expect(requiredConfirmations).to.be.equal(3);
              });
          });

          describe("addGuardian", () => {
              it("should revert if called by address which is not an owner.", async () => {
                  const [_, account2, account3] = await ethers.getSigners();

                  await expect(
                      guardian.connect(account2).addGuardian(account3.address)
                  ).to.be.revertedWith("Ownable: caller is not the owner");
              });

              it("should add new guardian.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  const tx: ContractTransaction = await guardian.addGuardian(
                      account2.address
                  );

                  await tx.wait(1);

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
                      "Guardian__CanOnlyChangeAfterDelayPeriod"
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
                          "Guardian__GuardianDoesNotExist"
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

                      const tx: ContractTransaction =
                          await guardian.addGuardians(newGuardians);

                      await tx.wait(1);

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

              it("should revert if there is no guardians to remove.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  await expect(
                      guardian.removeGuardian(account2.address)
                  ).to.be.revertedWithCustomError(
                      guardian,
                      "Guardian__GuardiansListIsEmpty"
                  );
              });

              it("should revert if delay time is not passed before removing a guardian.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  const tx: ContractTransaction = await guardian.addGuardian(
                      account2.address
                  );

                  await tx.wait(1);

                  await expect(
                      guardian.removeGuardian(account2.address)
                  ).to.be.revertedWithCustomError(
                      guardian,
                      "Guardian__CanOnlyRemoveAfterDelayPeriod"
                  );
              });

              describe("removeGuardian - After Delay", () => {
                  beforeEach(async () => {
                      const removalTime: BigNumber =
                          await guardian.getLastGuardianRemovalTime();

                      const delayTime: BigNumber =
                          await guardian.getRemoveGuardianDelay();

                      await network.provider.send("evm_increaseTime", [
                          removalTime.toNumber() + delayTime.toNumber(),
                      ]);
                  });

                  it("should revert if the `guardian` address does not exist.", async () => {
                      const [_, account2] = await ethers.getSigners();

                      await expect(
                          guardian.removeGuardian(account2.address)
                      ).to.be.revertedWithCustomError(
                          guardian,
                          "Guardian__GuardianDoesNotExist"
                      );
                  });
              });
          });
      });
