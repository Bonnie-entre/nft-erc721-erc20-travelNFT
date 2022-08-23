# NFT - Travel Ticket

![Screenshot](screenshot.png)
on testnet rinkeby: https://rinkeby.etherscan.io/address/0xf49a30a3205E9E1f1AC748481f26BAeD344Fb3A9

<br>
*once install packga "hardhat-shorthand", we can replace "hardhat" in cml by "hh"*

<br>

## Usage

use package hardhat...

### Deploy the Contract

-   all contract

    ```
    // assign network
    yarn hardhat deploy --network rinkeby

    // local network
    yarn hardhat deploy
    ```

-   specific contract

    ```
    // tags decide in ./depoly/deploy.js
    yarn hardhat deploy --network rinkeby --tags "XXX"
    ```

<br>

### Verify

Normally, it would verify automatically when deploy<br>
If not, can run

-   without argument

    ```
    yarn hardhat verify --network rinkeby "CONTRACT_ADDRESS"
    ```

-   with argument
    first create an argument.js file

    ```
    yarn hardhat verify --network rinkeby --constructor-args arguments.js "CONTRACT_ADDRESS"
    ```

<br>

### Test
At the same time, can get the gas report
```
yarn hardhat test
```
<br>

### Image & .json

-   IPFS
    use filebase
-   composite image
    [HashLips/hashlips_art_enginePublic
    ](https://github.com/HashLips/hashlips_art_engine)

<br><br>

## Gas Improve

Sructure
- The more often use function, put more ahead 
-  Replace if-else by ?:, and put easier fire situation into if statement

Function using
- Not override tokenURI(), by get rid of ".json" for each filename
-   Use merkle tree, not array mapping 
-   Don't use totalSupply() from ERC721Enumerable.sol, which needs 2 override function, and cost 400000 gas more.
-   Import Ownable.sol, not write on my own
-   Less math calculate

<br><br>

## Encounter Error

### Error: ENOENT: no such file or directory, open... artifacts/build-info ...

```
yarn hardhat clean
```

<br>
