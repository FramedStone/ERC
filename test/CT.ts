import { expect } from "chai"
import hre, { ethers } from "hardhat"

describe("User Topup CT Token", function() {
  let smartContract: any, smartContract_instance: any
  let owner: any, buyer: any, seller: any
  
  beforeEach(async function() {
    [owner, buyer, seller] = await ethers.getSigners()

    smartContract = await ethers.getContractFactory("CT_ERC20") // contract name as in .sol
    smartContract_instance = await smartContract.deploy(owner.address) // owner should deploy smart contract
  })

  it("should let users to mint 100 tokens with their ethers and emit event", async function() {
    // expected mint value
    const expected_mintedAmount = 100
    
    // token amount to be minted && token value
    const amount = ethers.parseEther(expected_mintedAmount.toString())
    const _amount = expected_mintedAmount
    const token_value = await smartContract_instance.token_value()
    const final_value = BigInt(_amount) * token_value

    // buyers mint token && expect event to be emit
    await expect(smartContract_instance.connect(buyer).mint_token(buyer.address, amount, {
      value: final_value
    }))
    .to.emit(smartContract_instance, "tokens_minted")
    .withArgs(buyer.address, amount)

    const actual_mintedAmount = ethers.formatEther(await smartContract_instance.balanceOf(buyer.address)) // format wei to ether
    expect(expected_mintedAmount).to.equal(Number(actual_mintedAmount))
  })

  it("should let users to mint 100 tokens with permit and emit event", async function() {
    // smart contract address
    const contract_address = await smartContract_instance.getAddress()

    // expected mint value
    const expected_mintedAmount = 100

    // permit variables
    const nonce = await smartContract_instance.nonces(owner.address)
    const deadline = ethers.MaxUint256
    const amount = ethers.parseEther(expected_mintedAmount.toString())

    // signature v6
    const domain = {
      name: "Carousell Token",
      version: "1",
      verifyingContract: contract_address, 
      chainId: hre.network.config.chainId //hardhat chainID
    }

    const types = {
        Permit: [
          { name: 'owner', type: 'address' },
          { name: 'spender', type: 'address' },
          { name: 'value', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' },
        ]
    }

    const value = {
        owner: owner.address,
        spender: buyer.address,
        value: amount,
        nonce: nonce,
        deadline: deadline,
    }

    const signature = await owner.signTypedData(domain, types, value);
    const {v,r,s} = ethers.Signature.from(signature);

    // owner permit tokens && expect event to be emit
    await expect(smartContract_instance.permit_token(owner.address, buyer.address, amount, deadline, v, r, s))
    .to.emit(smartContract_instance, "tokens_permitted")
    .withArgs(buyer.address, amount)

    expect(await smartContract_instance.balanceOf(buyer.address)).to.equal(amount)
  })
  
  it("should simulate buyer transfer ERC20 tokens to seller", async function() {
    // expect amount to be transferred
    const expected_transfferedAmount = 100

    // token amount to be transferred && token value
    const amount = ethers.parseEther(expected_transfferedAmount.toString())
    const _amount = expected_transfferedAmount
    const token_value = await smartContract_instance.token_value()
    const final_value = BigInt(_amount) * token_value

    // buyers mint token && expect event to be emit
    await expect(smartContract_instance.connect(buyer).mint_token(buyer.address, amount, {
      value: final_value
    }))
    .to.emit(smartContract_instance, "tokens_minted")
    .withArgs(buyer.address, amount)

    // buyers transfer token to seller && expect event to be emit
    await expect(smartContract_instance.connect(buyer).transfer_token(buyer.address, seller.address, amount))
    .to.emit(smartContract_instance, "tokens_transferred")
    .withArgs(seller.address, amount)
  })

  it("should simulate seller and owner withdrawal", async function() {
    // expect amount to be transferred
    const expected_transfferedAmount = 100

    // token amount to be withdraw && token value
    const amount = ethers.parseEther(expected_transfferedAmount.toString())
    const _amount = expected_transfferedAmount
    const token_value = await smartContract_instance.token_value()
    const final_value = BigInt(_amount) * token_value

    // buyers mint token && expect event to be emit
    await expect(smartContract_instance.connect(buyer).mint_token(buyer.address, amount, {
      value: final_value
    }))
    .to.emit(smartContract_instance, "tokens_minted")
    .withArgs(buyer.address, amount)

    // buyers transfer token to seller && expect event to be emit
    await expect(smartContract_instance.connect(buyer).transfer_token(buyer.address, seller.address, amount))
    .to.emit(smartContract_instance, "tokens_transferred")
    .withArgs(seller.address, amount)

    // seller withdraw token && expect event to be emit
    await expect(smartContract_instance.connect(seller).withdraw())
    .to.emit(smartContract_instance, "withdrawalUser")
    .withArgs(seller.address, await smartContract_instance.holder_benificialamount(seller.address))

    // owner withdraw token && expect event to be emit
    await expect(smartContract_instance.connect(owner)._withdraw())
    .to.emit(smartContract_instance, "withdrawalOwner")
    .withArgs(owner.address, await smartContract_instance.total_benificialamount())
  })
})