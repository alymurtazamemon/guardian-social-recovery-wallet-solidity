import { deployments, ethers, getNamedAccounts, network } from "hardhat";
import { developmentChains } from "../../helper-hardhat-config";
import { Guardian } from "../../typechain-types";
import { expect } from "chai";
import { BigNumber, ContractTransaction } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// * if the newwork will be hardhat or localhost then these tests will be run.
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("FundsManager Contract - Unit Tests", () => {
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
                          "Error__InvalidAmount"
                      )
                      .withArgs("FundsManager", 0);
              });

              it("should revert if amount is greater than daily transfer limit.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  await expect(guardian.send(account2.address, oneEther.mul(2)))
                      .to.be.revertedWithCustomError(
                          guardian,
                          "Error__DailyTransferLimitExceed"
                      )
                      .withArgs("FundsManager", oneEther.mul(2));
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
                      "Error__TransactionFailed"
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
                          "Error__BalanceIsZero"
                      )
                      .withArgs("FundsManager", 0);
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
                          "Error__DailyTransferLimitExceed"
                      )
                      .withArgs("FundsManager", oneEther.mul(2));
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

          describe("requestToUpdateDailyTransferLimit", () => {
              it("should revert if called by an address which is not an owner.", async () => {
                  const [_, account2, account3] = await ethers.getSigners();

                  await expect(
                      guardian
                          .connect(account2)
                          .requestToUpdateDailyTransferLimit(oneEther.mul(2))
                  ).to.be.revertedWith("Ownable: caller is not the owner");
              });

              it("should revert if the limit is less than or equal to zero.", async () => {
                  await expect(guardian.requestToUpdateDailyTransferLimit(0))
                      .to.be.revertedWithCustomError(
                          guardian,
                          "Error__InvalidLimit"
                      )
                      .withArgs("FundsManager", 0);
              });

              it("should request to update the daily limit.", async () => {
                  const status: boolean =
                      await guardian.getDailyTransferLimitUpdateRequestStatus();

                  expect(status).to.be.false;

                  const tx: ContractTransaction =
                      await guardian.requestToUpdateDailyTransferLimit(
                          oneEther.mul(2)
                      );

                  await tx.wait(1);

                  const updatedStatus: boolean =
                      await guardian.getDailyTransferLimitUpdateRequestStatus();

                  expect(updatedStatus).to.be.true;
              });
          });

          describe("confirmDailyTransferLimitRequest", () => {
              it("should revert if guardians list is empty.", async () => {
                  await expect(
                      guardian.confirmDailyTransferLimitRequest()
                  ).to.be.revertedWithCustomError(
                      guardian,
                      "Error__GuardiansListIsEmpty"
                  );
              });

              describe("confirmDailyTransferLimitRequest - After Adding Guardians", () => {
                  beforeEach(async () => {
                      const [_, account2, account3, account4] =
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

                  it("should revert if daily transfer limit update not requested by the owner.", async () => {
                      await expect(
                          guardian.confirmDailyTransferLimitRequest()
                      ).to.be.revertedWithCustomError(
                          guardian,
                          "Error__UpdateNotRequestedByOwner"
                      );
                  });

                  describe("confirmDailyTransferLimitRequest - After Request", () => {
                      beforeEach(async () => {
                          const tx: ContractTransaction =
                              await guardian.requestToUpdateDailyTransferLimit(
                                  oneEther.mul(2)
                              );

                          await tx.wait(1);
                      });

                      it("should revert if confirmed after comfirmation duration period.", async () => {
                          const requestTime: BigNumber =
                              await guardian.getLastDailyTransferUpdateRequestTime();

                          const confirmationTime: BigNumber =
                              await guardian.getDailyTransferLimitUpdateConfirmationTime();

                          await network.provider.send("evm_increaseTime", [
                              requestTime.toNumber() +
                                  confirmationTime.toNumber() +
                                  1,
                          ]);

                          await expect(
                              guardian.confirmDailyTransferLimitRequest()
                          ).to.be.revertedWithCustomError(
                              guardian,
                              "Error__RequestTimeExpired"
                          );
                      });

                      it("should revert if an address does not exist in guardians list.", async () => {
                          const [_, account2, account3, account4, account5] =
                              await ethers.getSigners();

                          await expect(
                              guardian
                                  .connect(account5)
                                  .confirmDailyTransferLimitRequest()
                          )
                              .to.be.revertedWithCustomError(
                                  guardian,
                                  "Error__AddressNotFoundAsGuardian"
                              )
                              .withArgs("FundsManager", account5.address);
                      });

                      it("should confirm the daily transfer update request.", async () => {
                          const [_, account2] = await ethers.getSigners();

                          const status: Boolean =
                              await guardian.getGuardianConfirmationStatus(
                                  account2.address
                              );

                          expect(status).to.be.false;

                          const tx: ContractTransaction = await guardian
                              .connect(account2)
                              .confirmDailyTransferLimitRequest();

                          await tx.wait(1);

                          const updatedStatus: Boolean =
                              await guardian.getGuardianConfirmationStatus(
                                  account2.address
                              );

                          expect(updatedStatus).to.be.true;
                      });

                      it("should revert if daily transfer update request already confirmed by a guardian.", async () => {
                          const [_, account2] = await ethers.getSigners();

                          const status: Boolean =
                              await guardian.getGuardianConfirmationStatus(
                                  account2.address
                              );

                          expect(status).to.be.false;

                          const tx: ContractTransaction = await guardian
                              .connect(account2)
                              .confirmDailyTransferLimitRequest();

                          await tx.wait(1);

                          const updatedStatus: Boolean =
                              await guardian.getGuardianConfirmationStatus(
                                  account2.address
                              );

                          expect(updatedStatus).to.be.true;

                          await expect(
                              guardian
                                  .connect(account2)
                                  .confirmDailyTransferLimitRequest()
                          )
                              .to.be.revertedWithCustomError(
                                  guardian,
                                  "Error__AlreadyConfirmedByGuardian"
                              )
                              .withArgs("FundsManager", account2.address);
                      });
                  });
              });
          });

          describe("confirmAndUpdate", () => {
              it("should revert if called by an address which is not an owner.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  await expect(
                      guardian.connect(account2).confirmAndUpdate()
                  ).to.be.revertedWith("Ownable: caller is not the owner");
              });

              it("should revert if guardians does not exist.", async () => {
                  await expect(
                      guardian.confirmAndUpdate()
                  ).to.be.revertedWithCustomError(
                      guardian,
                      "Error__GuardiansListIsEmpty"
                  );
              });

              describe("confirmAndUpdate - After Adding Guardians", () => {
                  beforeEach(async () => {
                      const [_, account2, account3, account4] =
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

                  it("should revert if daily transfer update not requested by an owner.", async () => {
                      await expect(
                          guardian.confirmAndUpdate()
                      ).to.be.revertedWithCustomError(
                          guardian,
                          "Error__UpdateNotRequestedByOwner"
                      );
                  });

                  describe("confirmAndUpdate - After Request", () => {
                      beforeEach(async () => {
                          const tx: ContractTransaction =
                              await guardian.requestToUpdateDailyTransferLimit(
                                  oneEther.mul(2)
                              );

                          await tx.wait(1);
                      });

                      it("should revert if confirmed after confirmation duration.", async () => {
                          const requestTime: BigNumber =
                              await guardian.getLastDailyTransferUpdateRequestTime();

                          const confirmationTime: BigNumber =
                              await guardian.getDailyTransferLimitUpdateConfirmationTime();

                          await network.provider.send("evm_increaseTime", [
                              requestTime.toNumber() +
                                  confirmationTime.toNumber() +
                                  1,
                          ]);

                          await expect(
                              guardian.confirmAndUpdate()
                          ).to.be.revertedWithCustomError(
                              guardian,
                              "Error__RequestTimeExpired"
                          );
                      });

                      it("should revert if not confirmed by required number of guardians.", async () => {
                          const [_, account2] = await ethers.getSigners();

                          const tx: ContractTransaction = await guardian
                              .connect(account2)
                              .confirmDailyTransferLimitRequest();

                          await tx.wait(1);

                          const requiredConfirmations: BigNumber =
                              await guardian.getRequiredConfirmations();

                          await expect(guardian.confirmAndUpdate())
                              .to.be.revertedWithCustomError(
                                  guardian,
                                  "Error__RequiredConfirmationsNotMet"
                              )
                              .withArgs(
                                  "FundsManager",
                                  requiredConfirmations.toNumber()
                              );
                      });

                      it("should update the daily transfer limit after all guardians confirmation.", async () => {
                          const [_, account2, account3, account4] =
                              await ethers.getSigners();

                          const guardians: SignerWithAddress[] = [
                              account2,
                              account3,
                              account4,
                          ];

                          for (let i = 0; i < guardians.length; i++) {
                              const tx: ContractTransaction = await guardian
                                  .connect(guardians[i])
                                  .confirmDailyTransferLimitRequest();

                              await tx.wait(1);
                          }

                          const dailyTransferLimit: BigNumber =
                              await guardian.getDailyTransferLimit();

                          expect(dailyTransferLimit).to.be.equal(oneEther);

                          const tx: ContractTransaction =
                              await guardian.confirmAndUpdate();

                          await tx.wait(1);

                          const updatedDailyTransferLimit: BigNumber =
                              await guardian.getDailyTransferLimit();

                          expect(updatedDailyTransferLimit).to.be.equal(
                              oneEther.mul(2)
                          );

                          const requestStatus: Boolean =
                              await guardian.getDailyTransferLimitUpdateRequestStatus();

                          expect(requestStatus).to.be.false;

                          for (let i = 0; i < guardians.length; i++) {
                              const confimationStatus = await guardian
                                  .connect(guardians[i])
                                  .getGuardianConfirmationStatus(
                                      guardians[i].address
                                  );

                              expect(confimationStatus).to.be.false;
                          }
                      });
                  });
              });
          });

          describe("getBalanceInUSD", () => {
              it("should get the balance in USD.", async () => {
                  const balanceInUsd = await guardian.getBalanceInUSD();
                  expect(balanceInUsd).to.be.equal(0);
              });
          });

          describe("getDailyTransferLimitInUSD", () => {
              it("should return the price of ETH/USD.", async () => {
                  const priceInUSD =
                      await guardian.getDailyTransferLimitInUSD();
                  expect(priceInUSD).to.be.equal(
                      ethers.utils.parseEther("1665")
                  );
              });
          });

          describe("getPrice", () => {
              it("should return the price of ETH/USD.", async () => {
                  const price = await guardian.getPrice();
                  expect(price).to.be.equal(ethers.utils.parseEther("1665"));
              });
          });
      });
