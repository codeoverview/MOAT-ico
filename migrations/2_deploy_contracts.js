// var ConvertLib = artifacts.require("./ConvertLib.sol");
// var Presale = artifacts.require('./Presale.sol')
var ICO = artifacts.require('./ICO.sol')

const curTime = Date.now() / 1000 | 0

module.exports = function (deployer) {
  // deployer.deploy(ConvertLib)
  // deployer.deploy(ICO, curTime+200, curTime + (60 * 60 * 24 * 3), '0x1') // TODO replace 0x1 with real wallet address
}
