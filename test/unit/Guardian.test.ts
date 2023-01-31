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
              it("should revert if amount is greater than daily transfer limit.", async () => {
                  const [_, account2] = await ethers.getSigners();

                  await expect(guardian.send(account2.address, oneEther.mul(2)))
                      .to.be.revertedWithCustomError(
                          guardian,
                          "Guardian__DailyTransferLimitExceed"
                      )
                      .withArgs(oneEther.mul(2));
              });
          });
      });
