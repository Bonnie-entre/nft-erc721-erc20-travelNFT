// remain: check baseUri() &　balanceOf(addr1)
const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")
const { BigNumber } = require("ethers");

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("erc721a NFT Unit Tests", function () {
    let base, owner, addr1
    let price = ethers.utils.parseEther("0.005");

    beforeEach(async () => {
      [owner, addr1] = await ethers.getSigners();

      const baseFactory = await ethers.getContractFactory("NFT", owner);
      base = await baseFactory.deploy();
      await base.deployed();
      // console.log(addr1); //0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    })

    describe("isSaleActive test", function () {
      it("reverts if isSaleActive = false", async function () {
        await expect(base.connect(owner).mintPublic(1)).to.be.revertedWith("Public mint is not active")
      })

      it("revert if not contract owner to call function setIsPublicSaleActive = true", async function () {
        await expect(base.connect(addr1).setIsPublicSaleActive(true)).to.be.revertedWith("Ownable: caller is not the owner");
      })

      it("Call function to setIsPublicSaleActive = true, and mint 1 NFT", async function () {
        await base.setIsPublicSaleActive(true);
        await base.connect(addr1).mintPublic(1)
        expect(await base.connect(owner).totalSupply()).to.eq(1);
      })
    })

    describe("mintPublic() function test", function () {
      it("reverts if not enough ether sent, mint >1 NFT", async function () {
        await base.setIsPublicSaleActive(true);
        await expect(base.connect(addr1).mintPublic(2)).to.revertedWith("Not enough ether sent");
      })

      it("mint 1 NFT", async function () {
        await base.setIsPublicSaleActive(true);
        await base.connect(addr1).mintPublic(1);
        // expect( await base.balanceOf(addr1.adddress) ).to.eq(2);
        expect(await base.connect(owner).totalSupply()).to.eq(1);
      })

      it("with enough ethers, mint 5 NFT", async function () {
        await base.setIsPublicSaleActive(true);
        await base.connect(addr1).mintPublic(5, 
          { value: BigNumber.from(price).mul(3).toString() });  //ethers.utils.parseEther("0.015")
        // expect( await base.balanceOf(addr1.adddress) ).to.eq(2);
        expect(await base.connect(owner).totalSupply()).to.eq(5);
      })

      it("check balance & mint with enough ethers, mint 5 NFT", async function () {
        await base.setIsPublicSaleActive(true);
        await base.connect(addr1).mintPublic(1);
        // expect( await base.balanceOf(addr1.adddress) ).to.eq(1);
        expect(await base.connect(owner).totalSupply()).to.eq(1);
        await base.connect(addr1).mintPublic(1, { value: price });
        // expect( await base.balanceOf(addr1.adddress) ).to.eq(2);
        expect(await base.connect(owner).totalSupply()).to.eq(2);
      })

    })

    describe("isWhiteSaleActive test", function () {
      it("reverts if isWhiteSaleActive = false", async function () {
        await expect(base.connect(owner).mintAllowList([], 1)).to.be.revertedWith("Allowlist mint is not active")
      })

      it("revert if not contract owner to call function isWhiteSaleActive = true", async function () {
        await expect(base.connect(addr1).setIsWhiteSaleActive(true)).to.be.revertedWith("Ownable: caller is not the owner");
      })
    })

    describe("isValid() function test", async () => {
      it("setRoot() and call isValid() function", async () => {
        await base.connect(owner).setRoot("0x5b7879adb5297db6f1d7cfd57c317229c136825f2ea2575d976b472fff662f7b");
        expect(await base.connect(owner).isValid(['0xc21ba819004fa273fb9b334fb970dcc3cf16a4562629c1f49542000b6cd0c655', '0xe467c02201f6ccff8dc14d70bf00e8bd2f6d2fc31f703ee3326f1ae45b0569db', '0xb49abd4102a5911165e24fb8d9908fce24f2d68b3b60a8b381f5c9b7bda9d7b8', '0xc65cff29666ef8cef0cf6081acf536cc4b6214b2788fffaa0bf9cbbbd0a1f72a'], '0x5931b4ed56ace4c46b68524cb5bcbf4195f1bbaacbe5228fbd090546c88dd229')).to.eq(true);
      })
    })

    describe("mintAllowlist() function test", async () => {
      it("check proof and mint 1 NFT", async () => {
        // Remember to put the hardhat test addr1 into merkle tree
        await base.connect(owner).setIsWhiteSaleActive(true);
        await base.connect(owner).setRoot("0x6d6ec88315b159428e0d5f4fa3da3c3da32bad1f0b41975f25b201d0ef6b420e");
        await base.connect(addr1).mintAllowList(['0xb7b19092bad498eae34230a9e14c8ce3d9d85b2bb91212108c9d47d1948acfeb','0x1f957db768cd7253fad82a8a30755840d536fb0ffca7c5c73fe9d815b1bc2f2f','0x924862b314bd38813a325167aca7caee16318f07303bd8e9f81bbe5808575fbf','0xe5076a139576746fd34a0fd9c21222dc274a909421fcbaa332a5af7272b6dcb1','0x148c730f8169681c1ebfb5626eb20af3d2351445463a1fdc5d0b116c62dc58c8','0x5712507eeb3d7b48e5876f21fc871656c2379464b480c8e89c50c2a1e8f58ac5'], 1);
        expect(await base.connect(owner).totalSupply()).to.eq(1);
      })

      it("check proof and mint 1 NFT, with wrong leaf", async () => {
        await base.connect(owner).setIsWhiteSaleActive(true);
        await base.connect(owner).setRoot("0x5b7879adb5297db6f1d7cfd57c317229c136825f2ea2575d976b472fff662f7b");
        await expect( base.connect(addr1).mintAllowList(['0xc21ba819004fa273fb9b334fb970dcc3cf16a4562629c1f49542000b6cd0c655', '0xe467c02201f6ccff8dc14d70bf00e8bd2f6d2fc31f703ee3326f1ae45b0569db', '0xb49abd4102a5911165e24fb8d9908fce24f2d68b3b60a8b381f5c9b7bda9d7b8', '0xc65cff29666ef8cef0cf6081acf536cc4b6214b2788fffaa0bf9cbbbd0a1f72a'], 1)).to.revertedWith("Not a part of Allowlist");
      })

      it("mint 4 NFT with enough ether sent", async function(){
        await base.connect(owner).setIsWhiteSaleActive(true);
        await base.connect(owner).setRoot("0x6d6ec88315b159428e0d5f4fa3da3c3da32bad1f0b41975f25b201d0ef6b420e");
        await base.connect(addr1).mintAllowList(
          ['0xb7b19092bad498eae34230a9e14c8ce3d9d85b2bb91212108c9d47d1948acfeb','0x1f957db768cd7253fad82a8a30755840d536fb0ffca7c5c73fe9d815b1bc2f2f','0x924862b314bd38813a325167aca7caee16318f07303bd8e9f81bbe5808575fbf','0xe5076a139576746fd34a0fd9c21222dc274a909421fcbaa332a5af7272b6dcb1','0x148c730f8169681c1ebfb5626eb20af3d2351445463a1fdc5d0b116c62dc58c8','0x5712507eeb3d7b48e5876f21fc871656c2379464b480c8e89c50c2a1e8f58ac5'],
         4,
          { value: BigNumber.from(price).mul(3).toString() }
        )
        expect(await base.connect(owner).totalSupply()).to.eq(4);
      })

      it("mint 5 NFT with same ammount of ethers", async function(){
        await base.connect(owner).setIsWhiteSaleActive(true);
        await base.connect(owner).setRoot("0x6d6ec88315b159428e0d5f4fa3da3c3da32bad1f0b41975f25b201d0ef6b420e");
        await base.connect(addr1).mintAllowList(
          ['0xb7b19092bad498eae34230a9e14c8ce3d9d85b2bb91212108c9d47d1948acfeb','0x1f957db768cd7253fad82a8a30755840d536fb0ffca7c5c73fe9d815b1bc2f2f','0x924862b314bd38813a325167aca7caee16318f07303bd8e9f81bbe5808575fbf','0xe5076a139576746fd34a0fd9c21222dc274a909421fcbaa332a5af7272b6dcb1','0x148c730f8169681c1ebfb5626eb20af3d2351445463a1fdc5d0b116c62dc58c8','0x5712507eeb3d7b48e5876f21fc871656c2379464b480c8e89c50c2a1e8f58ac5'],
         5,
          { value: BigNumber.from(price).mul(3).toString() }
        )
        expect(await base.connect(owner).totalSupply()).to.eq(5);
      })
    })
    
    describe("devMint() function test", function () {
      // can do without setIsPublicSaleActive=true

      it("devMint 1 NFT", async function () {
        await base.connect(owner).devMint(1)
        expect(await base.connect(owner).totalSupply()).to.eq(1);
      })

      it("revert if not owner ,devMint 2 NFT", async function () {
        await expect(base.connect(addr1).devMint(2)).to.revertedWith("Ownable: caller is not the owner");
      })

      it("devMint 5 NFT", async function () {
        await base.connect(owner).devMint(5);
        expect(await base.connect(owner).totalSupply()).to.eq(5);
        // expect( await base.balanceOf(owner.adddress) ).to.eq(5);
      })

      it("devMint 10 NFT", async function () {
        await base.connect(owner).devMint(10);
        expect(await base.connect(owner).totalSupply()).to.eq(10);
        // expect( await base.balanceOf(owner.adddress) ).to.eq(5);
      })


    })

    describe("check mint limitation test", function () {
      it("revert if out of personal mint limit", async () => {
        await base.setIsPublicSaleActive(true);
        await expect(base.connect(addr1).mintPublic(6)).to.revertedWith("Exceeded the personal limit");
      })

      it("revert if out of personal mintLimit, by mint twice", async () => {
        await base.setIsPublicSaleActive(true);
        await base.connect(addr1).mintPublic(2, { value: price });
        await expect(base.connect(addr1).mintPublic(4, { value: ethers.utils.parseEther("0.015") })).to.revertedWith("Exceeded the personal limit");
      })

      it("check maxSupply mint limit, by devMint()", async () => {
        await base.connect(owner).devMint(3333)
        expect(await base.connect(owner).totalSupply()).to.eq(3333);
      })

      it("revert if out of maxSupply limit, by devMint()", async () => {
        await expect(base.connect(owner).devMint(3334)).to.revertedWith("Not enough Seatbelts left");
      })

      it("revert if out of maxSupply limit, by mintPublic() & devMint()", async () => {
        await base.setIsPublicSaleActive(true);
        await base.connect(addr1).mintPublic(2, { value: price });
        await expect(base.connect(owner).devMint(3332)).to.revertedWith("Not enough Seatbelts left");
      })

      it("revert if out of maxSupply limit, by devMint() & mintPublic()", async () => {
        await base.setIsPublicSaleActive(true);
        await base.connect(owner).devMint(3332);
        await expect(base.connect(addr1).mintPublic(2, { value: price })).to.revertedWith("Not enough Seatbelts left");
      })

      it("check maxSupply mint limit, by mint(), called by  mintWhitelist()", async()=>{
        // public mint
        await base.setIsPublicSaleActive(true);
        await base.connect(owner).mintPublic(5, { value: BigNumber.from(price).mul(3).toString() });
        // allowlist mint
        await base.connect(owner).setIsWhiteSaleActive(true);
        await base.connect(owner).setRoot("0x6d6ec88315b159428e0d5f4fa3da3c3da32bad1f0b41975f25b201d0ef6b420e");
        await base.connect(addr1).mintAllowList(
          ['0xb7b19092bad498eae34230a9e14c8ce3d9d85b2bb91212108c9d47d1948acfeb','0x1f957db768cd7253fad82a8a30755840d536fb0ffca7c5c73fe9d815b1bc2f2f','0x924862b314bd38813a325167aca7caee16318f07303bd8e9f81bbe5808575fbf','0xe5076a139576746fd34a0fd9c21222dc274a909421fcbaa332a5af7272b6dcb1','0x148c730f8169681c1ebfb5626eb20af3d2351445463a1fdc5d0b116c62dc58c8','0x5712507eeb3d7b48e5876f21fc871656c2379464b480c8e89c50c2a1e8f58ac5'],
         5,
          { value: BigNumber.from(price).mul(3).toString() }
        )
        
        // developer mint
        await base.connect(owner).devMint(3323);
        expect(await base.connect(owner).totalSupply()).to.eq(3333);
        await expect(base.connect(owner).devMint(1)).to.revertedWith("Not enough Seatbelts left");
      })
    })

    describe("withdraw() function test", async()=>{
      it("before mint check 0 balance", async()=>{
        const contractBalance = await ethers.provider.getBalance(base.address);
        expect(contractBalance.toString()).to.eq('0');
      })

      it("after mint check balance", async()=>{
        await base.setIsPublicSaleActive(true);
        await base.connect(addr1).mintPublic(5, { value: BigNumber.from(price).mul(3).toString() });
        const contractBalance = await ethers.provider.getBalance(base.address);
        expect(contractBalance.toString()).to.eq(BigNumber.from(price).mul(3).toString());
        // expect( await( (await ethers.provider.getBalance(base.address)) - BigNumber.from(price).mul(3) ).toString()).to.eq('0');
      })

      it("withdraw & check balance", async()=>{
        await base.setIsPublicSaleActive(true);
        await base.connect(addr1).mintPublic(5, { value: BigNumber.from(price).mul(3).toString() });
        const ownerBalance_before = await ethers.provider.getBalance(owner.address);        
        const contractBalance = await ethers.provider.getBalance(base.address);
        expect(contractBalance.toString()).to.eq(BigNumber.from(price).mul(3).toString());

        await base.connect(owner).withdraw();
        const ownerBalance_after = await ethers.provider.getBalance(owner.address);
        const contractBalance_after = await ethers.provider.getBalance(base.address);
        expect(contractBalance_after.toString()).to.eq('0');
        // expect(await ownerBalance_before.add(BigNumber.from(price).mul(3).toString()) ).to.eq(ownerBalance_after.toString());
        // ^ there seems to have some gas fee cost (AssertionError: Expected "9999883675730637257879" to be equal 9999883645114648699529)
      })

      it("revert if not owner to withdraw & check balance", async()=>{
        await base.setIsPublicSaleActive(true);
        await base.connect(addr1).mintPublic(5, { value: BigNumber.from(price).mul(3).toString() });
        const contractBalance = await ethers.provider.getBalance(base.address);
        expect(contractBalance.toString()).to.eq(BigNumber.from(price).mul(3).toString());
        await expect(base.connect(addr1).withdraw()).to.revertedWith("Ownable: caller is not the owner");
      })
    })

    describe("other settings function test", async()=>{
      it("before blindbox open", async()=>{
        await base.setIsPublicSaleActive(true);
        await base.connect(addr1).mintPublic(1);
        expect(await base.tokenURI(1)).to.eq('');
      })

      it("setBaseURI() function", async()=>{
        await base.setIsPublicSaleActive(true);
        await base.connect(addr1).mintPublic(1);
        await base.connect(owner).setBaseURI("ipfs://openblind/");
        expect( await base.tokenURI(1)).to.eq('ipfs://openblind/1');
      })

      it("setMintPrice() function", async()=>{
        await base.setIsPublicSaleActive(true);
        await base.connect(owner).setMintPrice(ethers.utils.parseEther("0.1"));
        await expect(base.connect(addr1).mintPublic(2, { value: BigNumber.from(price).toString() })).to.revertedWith("Not enough ether sent");
        base.connect(addr1).mintPublic(2, { value: ethers.utils.parseEther("0.1") })
        expect(await base.connect(owner).totalSupply()).to.eq(2);
      })
    })

  })
