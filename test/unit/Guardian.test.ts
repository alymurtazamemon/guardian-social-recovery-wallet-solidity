import { deployments, ethers, getNamedAccounts, network } from "hardhat";
import { developmentChains } from "../../helper-hardhat-config";
import { Guardian } from "../../typechain-types";
import { expect } from "chai";

// * if the newwork will be hardhat or localhost then these tests will be run.
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Guardian Contract - Unit Tests", () => {
          let deployer: string;
          let guardian: Guardian;

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

                  const tx = await deployer.sendTransaction({
                      to: guardian.address,
                      data: "0x",
                      value: ethers.utils.parseEther("1"),
                  });

                  await tx.wait(1);

                  expect(
                      (
                          await ethers.provider.getBalance(guardian.address)
                      ).toString()
                  ).to.be.equal(ethers.utils.parseEther("1"));
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

                  const tx = await deployer.sendTransaction({
                      to: guardian.address,
                      data: "0xFFFFFFFF",
                      value: ethers.utils.parseEther("1"),
                  });

                  await tx.wait(1);

                  expect(
                      (
                          await ethers.provider.getBalance(guardian.address)
                      ).toString()
                  ).to.be.equal(ethers.utils.parseEther("1"));
              });
          });

          describe("send", () => {
              it("should revert if amount is less than or equal to zero.", async () => {
                  const [_, addr2] = await ethers.getSigners();

                  await expect(guardian.send(addr2.address, 0))
                      .to.be.revertedWithCustomError(
                          guardian,
                          "Guardian__InvalidAmount"
                      )
                      .withArgs(0);
              });
          });
      });
