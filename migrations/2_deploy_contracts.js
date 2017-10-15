// var ConvertLib = artifacts.require("./ConvertLib.sol");
var Presale = artifacts.require('./Presale.sol')
var ICO = artifacts.require('./ICO.sol')

const curTime = Date.now() / 1000 | 0

module.exports = function (deployer) {
  // deployer.deploy(ConvertLib)
  deployer.deploy(Presale, curTime, '0x1').then(() => {
    let presale = Presale.deployed()
    deployer.deploy(ICO, 1000, presale, '0x1').catch((err) => {
      console.log(err)
    })
  })
}
