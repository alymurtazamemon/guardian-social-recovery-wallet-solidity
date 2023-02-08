import { deployments, ethers, getNamedAccounts, network } from "hardhat";
import { developmentChains } from "../../helper-hardhat-config";
import { Guardian, GuardianFactory } from "../../typechain-types";
import { BigNumber, ContractTransaction } from "ethers";
import { expect } from "chai";

// * if the newwork will be hardhat or localhost then these tests will be run.
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("GuardianFactory Contract - Unit Tests", () => {
          let deployer: string;
          let guardiansFactroy: GuardianFactory;
          let guardian: Guardian;

          beforeEach(async () => {
              if (!developmentChains.includes(network.name)) {
                  throw "You need to be on a development chain to run tests";
              }

              deployer = (await getNamedAccounts()).deployer;
              await deployments.fixture(["all"]);

              guardiansFactroy = await ethers.getContract(
                  "GuardianFactory",
                  deployer
              );
          });

          describe("createWallet", () => {
              it("should create a new wallet", async () => {
                  const tx: ContractTransaction =
                      await guardiansFactroy.createWallet();

                  await tx.wait(1);

                  const length: BigNumber =
                      await guardiansFactroy.getWalletsLength();

                  expect(length).to.be.equal(1);

                  const walletAddress: string =
                      await guardiansFactroy.getWallet();

                  guardian = await ethers.getContract(
                      "Guardian",
                      walletAddress
                  );

                  const owner = await guardian.owner();

                  expect(owner).to.be.equal(deployer);
              });
          });

          describe("updateWalletOwner", () => {
              beforeEach(async () => {
                  const [_, account2, account3, account4, account5] =
                      await ethers.getSigners();

                  const tx: ContractTransaction =
                      await guardiansFactroy.createWallet();

                  await tx.wait(1);

                  const walletAddress: string =
                      await guardiansFactroy.getWallet();

                  guardian = await ethers.getContractAt(
                      "Guardian",
                      walletAddress
                  );

                  const newGuardians: string[] = [
                      account2.address,
                      account3.address,
                      account4.address,
                  ];

                  for (let i = 0; i < newGuardians.length; i++) {
                      const addTime: BigNumber =
                          await guardian.getLastGuardianAddTime();

                      const delay: BigNumber =
                          await guardian.getAddGuardianDelay();

                      await network.provider.send("evm_increaseTime", [
                          addTime.toNumber() + delay.toNumber(),
                      ]);

                      const tx = await guardian.addGuardian(newGuardians[i]);
                      await tx.wait(1);
                  }

                  const tx2: ContractTransaction = await guardian
                      .connect(account2)
                      .requestToUpdateOwner(account5.address);

                  await tx2.wait(1);

                  const tx3: ContractTransaction = await guardian
                      .connect(account3)
                      .confirmUpdateOwnerRequest();

                  await tx3.wait(1);
              });

              it("should update wallet owner.", async () => {
                  const [_, account2, account3, account4, account5] =
                      await ethers.getSigners();

                  const owner = await guardian.owner();
                  expect(owner).to.be.equal(account5.address);

                  const nullNalletAddress = await guardiansFactroy.getWallet();
                  expect(nullNalletAddress).to.be.equal(
                      "0x0000000000000000000000000000000000000000"
                  );

                  const walletAddress = await guardiansFactroy
                      .connect(account5)
                      .getWallet();

                  expect(walletAddress).to.be.equal(guardian.address);
              });
          });
      });
