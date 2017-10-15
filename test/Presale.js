/* global it, contract, assert, web3, artifacts */

// const timeTravel = require('./util/timeTravel')
// const getTime = require('./util/getTime')
const getBlock = require('./util/getBlock')
const mineBlock = require('./util/mineBlock')
const Presale = artifacts.require('./Presale.sol')
const PresaleToken = artifacts.require('./PresaleToken.sol')
const assertFail = require('./util/assertFail')

contract('Presale', async function (accounts) {
  it('Tests run', async function () {
    assert.equal(true, true, 'base test failed')
  })
})
