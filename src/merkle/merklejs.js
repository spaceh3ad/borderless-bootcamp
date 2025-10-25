const keccak256 = require("keccak256");
const { default: MerkleTree } = require("merkletreejs");
const fs = require("fs");
const path = require("path");
// require("dotenv").config();

// Each entry: { address, amount, refClaimUUID, asset }
const entries = [
  {
    address: "0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e",
    amount: "100000000",
    refClaimUUID:
      "0xabc1230000000000000000000000000000000000000000000000000000000001",
    asset: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  },
  {
    address: "0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e",
    amount: "50000000",
    refClaimUUID:
      "0xabc1240000000000000000000000000000000000000000000000000000000002",
    asset: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  },
  {
    address: "0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e",
    amount: "75000000",
    refClaimUUID:
      "0xabc1250000000000000000000000000000000000000000000000000000000003",
    asset: "0x2282c726f54c93193e6b8e5bf1b82303dc11d36e",
  },
];

// Build leaves: keccak256(abi.encodePacked(address, amount, refClaimUUID, asset))
const leaves = entries.map(({ address, amount, refClaimUUID, asset }) =>
  keccak256(
    Buffer.concat([
      Buffer.from(address.slice(2).padStart(40, "0"), "hex"),
      Buffer.from(BigInt(amount).toString(16).padStart(64, "0"), "hex"),
      Buffer.from(refClaimUUID.slice(2).padStart(64, "0"), "hex"),
      Buffer.from(asset.slice(2).padStart(40, "0"), "hex"),
    ])
  )
);

// Construct Merkle tree
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
const bufferToHex = (x) => "0x" + x.toString("hex");
const merkleRoot = bufferToHex(tree.getRoot());

// Construct data with proofs
const data = entries.map(({ address, amount, refClaimUUID, asset }, i) => {
  const leaf = leaves[i];
  const proof = tree.getProof(leaf).map((x) => bufferToHex(x.data));
  return {
    address,
    amount,
    refClaimUUID,
    asset,
    leaf: bufferToHex(leaf),
    proof,
  };
});

// Final object
const whiteList = {
  merkleRoot,
  whiteList: data,
};

// Write to file
const filePath = path.resolve(__dirname, "merkleTree.json");
fs.writeFileSync(filePath, JSON.stringify(whiteList, null, 2));

console.log("MerkleTree generated ./merkleTree.json");
