/* global it, contract, assert, web3, artifacts */

// const timeTravel = require('./util/timeTravel')
// const getTime = require('./util/getTime')
const getBlock = require('./util/getBlock')
const mineBlock = require('./util/mineBlock')
const ICO = artifacts.require('./ICO.sol')
const Token = artifacts.require('./Token.sol')
const assertFail = require('./util/assertFail')
const Presale = artifacts.require('./Presale.sol')
const PresaleToken = artifacts.require('./PresaleToken.sol')

contract('ICO', async function (accounts) {
  it('Tests run', async function () {
    assert.equal(true, true, 'base test failed')
  })
})
