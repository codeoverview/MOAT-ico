// var ConvertLib = artifacts.require("./ConvertLib.sol");
// var Presale = artifacts.require('./Presale.sol')
var ICO = artifacts.require('./ICO.sol')

const curTime = Date.now() / 1000 | 0

module.exports = function (deployer) {
  // deployer.deploy(ConvertLib)
  deployer.deploy(ICO, curTime + 300, '0x2E254e8f64F9e5e6a88509a84328077B08DC9E32')
}
