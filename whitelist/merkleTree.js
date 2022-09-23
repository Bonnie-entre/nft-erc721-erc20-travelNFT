const { MerkleTree } = require("merkletreejs")
const keccak256 = require("keccak256")
require("dotenv").config({ path: "../.env" })
const { addresses } = require("./whitelist.js")

/* Build */
const buf2hex = (x) => "0x" + x.toString("hex")
const leaves = addresses.map((x) => keccak256(x))
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true })

async function buildMerkle() {
    return buf2hex(tree.getRoot())
}

/* Check */
async function checkleafProof(check_address) {
    const leaf = await keccak256(check_address)
    // const proof = await tree.getProof(leaf).map((x) => ( '"'+buf2hex(x.data)+'"' ))
    const proof = await tree.getProof(leaf).map((x) => ( buf2hex(x.data) ))
    return proof
}

module.exports = { checkleafProof, buildMerkle }

const getProof_Leaf = async (addr) => {
    console.log(`Leaf(keccak256): ${buf2hex(keccak256(addr))}`)
    const proof = await checkleafProof(addr)
    console.log(`Proof of leaf:\n${proof}`)
}

const getRoot = async () => {
    const root = await buildMerkle()
    console.log(`Root: ${root}`)
}


getRoot()
getProof_Leaf("0x0F19076149a083Bb2b345c28Ad64FAFCf7508A55")
