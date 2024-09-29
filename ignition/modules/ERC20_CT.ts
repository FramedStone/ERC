import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const CT_Module = buildModule("CT_ERC20", (m) => {
  const CT = m.contract("CT_ERC20");
  return { CT };
});

export default CT_Module;