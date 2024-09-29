import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const CT_Module = buildModule("CT_ERC1155", (m) => {
  const CT = m.contract("CT_ERC1155", ["deployer address", "metadata link", [1,2,3], [1,1,1]]);
  return { CT };
});

export default CT_Module;