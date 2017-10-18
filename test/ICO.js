/* global it, contract, assert, web3, artifacts */

const timeTravel = require('./util/timeTravel')
const getTime = require('./util/getTime')
const getBlock = require('./util/getBlock')
const mineBlock = require('./util/mineBlock')
const ICO = artifacts.require('./ICO.sol')
const Token = artifacts.require('./Token.sol')
const assertFail = require('./util/assertFail')

let days30 = 60 * 60 * 24 * 30
let days12 = 60 * 60 * 24 * 12

contract('ICO', async function (accounts) {
  it('Tests run', async function () {
    assert.equal(true, true, 'base test failed')
  })

  it('Time skipping works fine', async function () {
    await mineBlock()
    let curTime = await getTime()
    await timeTravel(100)
    await mineBlock(1)
    let minedTime = await getTime()
    assert.isAtLeast(minedTime, curTime + 100, 'Did not skip forward in time')
  })

  it('Allows contributions only during correct times', async function () {
    await mineBlock()
    let curTime = await getTime()
    console.log('Got here')
    let cs = await ICO.new(curTime + 20, curTime + days12 + 300, accounts[0], {from: accounts[0]})

    await web3.eth.sendTransaction({from: accounts[1], to: cs.address, value: 1000})
    let baseContrib = await cs.contributions(accounts[1])
    assert.equal(baseContrib, 0, 'Contribution preico worked before start')

    await timeTravel(100)

    await web3.eth.sendTransaction({from: accounts[1], to: cs.address, value: 1000, gas: 400000})
    let allowedContrib = await cs.contributions(accounts[1])
    assert.equal(allowedContrib.toNumber(), 2000, 'Contribution preico wrong amount')

    await timeTravel(days12)

    await web3.eth.sendTransaction({from: accounts[1], to: cs.address, value: 1000, gas: 400000})
    let intervalContrib = await cs.contributions(accounts[1])
    assert.equal(intervalContrib.toNumber(), 2000, 'Contribution preico was allowed after it ended')

    assertFail(async () => {
      await cs.setBaseRate(100, {from: accounts[1]})
    })
    await cs.setBaseRate(100, {from: accounts[0]})

    await timeTravel(300)

    await web3.eth.sendTransaction({from: accounts[1], to: cs.address, value: 1000, gas: 400000})
    let postContrib = await cs.contributions(accounts[1])
    let icoBalance = await cs.balanceOf(accounts[1])
    assert.equal(postContrib.toNumber(), 2000, 'Contribution preico was allowed after it ended once ico started')
    assert.equal(icoBalance.toNumber(), 100000, 'Did not receive tokens for contributing to ico')
  })
})
