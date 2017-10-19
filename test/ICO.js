/* global it, contract, assert, web3, artifacts */

const timeTravel = require('./util/timeTravel')
const getTime = require('./util/getTime')
const getBlock = require('./util/getBlock')
const mineBlock = require('./util/mineBlock')
const ICO = artifacts.require('./ICO.sol')
const Token = artifacts.require('./Token.sol')
const assertFail = require('./util/assertFail')

let day = 60 * 60 * 24
let days30 = day * 30
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

  it('Correct contrib times, and amounts lightly', async function () {
    await mineBlock()
    let curTime = await getTime()
    // console.log('Got here')
    let cs = await ICO.new(curTime + 20, curTime + days12 + 300, accounts[0], {from: accounts[0]})
    let token = Token.at(await cs.token())

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
    let icoBalance = await token.balanceOf(accounts[1])
    assert.equal(postContrib.toNumber(), 2000, 'Contribution preico was allowed after it ended once ico started')
    assert.equal(icoBalance.toNumber(), 100000, 'Did not receive tokens for contributing to ico')

    await timeTravel(days30)

    await web3.eth.sendTransaction({from: accounts[1], to: cs.address, value: 1000, gas: 400000})
    let blockedTokenBuy = await token.balanceOf(accounts[1])
    assert.equal(blockedTokenBuy.toNumber(), 100000, 'Bought tokens after ICO end')
  })

  it('Transfers blocked until tokens are released', async function () {
    await mineBlock()
    let curTime = await getTime()
    let cs = await ICO.new(curTime + 20, curTime + days12 + 300, accounts[0], {from: accounts[0]})
    let token = Token.at(await cs.token())

    await timeTravel(100)
    await timeTravel(days12)
    await cs.setBaseRate(100, {from: accounts[0]})
    await timeTravel(300)

    await web3.eth.sendTransaction({from: accounts[1], to: cs.address, value: 1000, gas: 400000})
    let icoBalance = await token.balanceOf(accounts[1])

    await timeTravel(days30)

    await assertFail(async () => {
      await token.transfer(accounts[0], 100, {from: accounts[1]})
    })

    await cs.releaseTokens()
    await token.transfer(accounts[0], 100, {from: accounts[1]})
    let senderBalance = await token.balanceOf(accounts[1])
    let receiverBalance = await token.balanceOf(accounts[0])
    assert.equal(senderBalance.toNumber() + receiverBalance.toNumber(), icoBalance.toNumber(), 'Tokens went missing or were created')
    assert.equal(receiverBalance.toNumber(), 100, 'Received wrong amount of tokens')
    assert.equal(senderBalance.toNumber(), icoBalance.toNumber() - 100, 'Sent wrong amount of tokens')
  })

  it('Correct contrib calculation and pre-ico distribution', async function () {
    await mineBlock()
    let curTime = await getTime()
    let cs = await ICO.new(curTime + 20, curTime + days12 + 300, accounts[0], {from: accounts[0]})
    let token = Token.at(await cs.token())

    await timeTravel(100)

    await web3.eth.sendTransaction({from: accounts[1], to: cs.address, value: 10 * 10 ** 18, gas: 400000})
    let contrib1 = await cs.contributions(accounts[1])
    await timeTravel(day * 2)
    await web3.eth.sendTransaction({from: accounts[2], to: cs.address, value: 10 * 10 ** 18, gas: 400000})
    let contrib2 = await cs.contributions(accounts[2])
    await timeTravel(day * 2)
    await web3.eth.sendTransaction({from: accounts[3], to: cs.address, value: 10 * 10 ** 18, gas: 400000})
    let contrib3 = await cs.contributions(accounts[3])
    await timeTravel(day * 2)
    await web3.eth.sendTransaction({from: accounts[4], to: cs.address, value: 10 * 10 ** 18, gas: 400000})
    let contrib4 = await cs.contributions(accounts[4])
    await timeTravel(day * 2)
    await web3.eth.sendTransaction({from: accounts[5], to: cs.address, value: 10 * 10 ** 18, gas: 400000})
    let contrib5 = await cs.contributions(accounts[5])
    await timeTravel(day * 2)
    await web3.eth.sendTransaction({from: accounts[6], to: cs.address, value: 10 * 10 ** 18, gas: 400000})
    let contrib6 = await cs.contributions(accounts[6])

    assert.equal(contrib1.toNumber(), 20 * 10 ** 18, 'Contribution preico wrong amount')
    assert.equal(contrib2.toNumber(), 19 * 10 ** 18, 'Contribution preico wrong amount')
    assert.equal(contrib3.toNumber(), 18 * 10 ** 18, 'Contribution preico wrong amount')
    assert.equal(contrib4.toNumber(), 17 * 10 ** 18, 'Contribution preico wrong amount')
    assert.equal(contrib5.toNumber(), 16 * 10 ** 18, 'Contribution preico wrong amount')
    assert.equal(contrib6.toNumber(), 15 * 10 ** 18, 'Contribution preico wrong amount')

    await timeTravel(day * 2)

    await cs.claimTokens({from: accounts[1]})
    await assertFail(async () => {
      await cs.claimTokens({from: accounts[1]})
    })
    await cs.claimTokens({from: accounts[2]})
    await cs.claimTokens({from: accounts[3]})
    await cs.claimTokens({from: accounts[4]})
    await cs.claimTokens({from: accounts[5]})
    await cs.claimTokens({from: accounts[6]})

    let balance1 = await token.balanceOf(accounts[1])
    let balance2 = await token.balanceOf(accounts[2])
    let balance3 = await token.balanceOf(accounts[3])
    let balance4 = await token.balanceOf(accounts[4])
    let balance5 = await token.balanceOf(accounts[5])
    let balance6 = await token.balanceOf(accounts[6])

    assert.equal(await cs.tokenValue(), 2380952, 'Wrong pre-ico token value calculated')

    assert.equal(balance1.toNumber(), contrib1.toNumber() * 2380952, 'User claimed wrong amount of tokens')
    assert.equal(balance2.toNumber(), contrib2.toNumber() * 2380952, 'User claimed wrong amount of tokens')
    assert.equal(balance3.toNumber(), contrib3.toNumber() * 2380952, 'User claimed wrong amount of tokens')
    assert.equal(balance4.toNumber(), contrib4.toNumber() * 2380952, 'User claimed wrong amount of tokens')
    assert.equal(balance5.toNumber(), contrib5.toNumber() * 2380952, 'User claimed wrong amount of tokens')
    assert.equal(balance6.toNumber(), contrib6.toNumber() * 2380952, 'User claimed wrong amount of tokens')
    assert.equal(balance1.toNumber(), balance5.toNumber() * 1.25, 'User did not get the correct relative amount of tokens')
  })

  it('Correct ICO calculation and distribution', async function () {
    await mineBlock()
    let curTime = await getTime()
    let cs = await ICO.new(curTime + 20, curTime + days12 + 300, accounts[0], {from: accounts[0]})
    let token = Token.at(await cs.token())

    await timeTravel(days12 + 25)
    await cs.setBaseRate(100, {from: accounts[0]})
    await timeTravel(500)

    await web3.eth.sendTransaction({from: accounts[1], to: cs.address, value: 10 * (10 ** 18), gas: 400000})
    await timeTravel(day * 5)
    await web3.eth.sendTransaction({from: accounts[2], to: cs.address, value: 10 * 10 ** 18, gas: 400000})
    await timeTravel(day * 5)
    await web3.eth.sendTransaction({from: accounts[3], to: cs.address, value: 10 * 10 ** 18, gas: 400000})
    await timeTravel(day * 5)
    await web3.eth.sendTransaction({from: accounts[4], to: cs.address, value: 10 * 10 ** 18, gas: 400000})
    await timeTravel(day * 5)
    await web3.eth.sendTransaction({from: accounts[5], to: cs.address, value: 10 * 10 ** 18, gas: 400000})
    await timeTravel(day * 5)
    await web3.eth.sendTransaction({from: accounts[6], to: cs.address, value: 10 * 10 ** 18, gas: 400000})

    let balance1 = await token.balanceOf(accounts[1])
    let balance2 = await token.balanceOf(accounts[2])
    let balance3 = await token.balanceOf(accounts[3])
    let balance4 = await token.balanceOf(accounts[4])
    let balance5 = await token.balanceOf(accounts[5])
    let balance6 = await token.balanceOf(accounts[6])

    assert.equal(balance1.toNumber(), 1000 * 10 ** 18, 'Balance from ico partcipation wrong amount')
    assert.equal(balance2.toNumber(), 900 * 10 ** 18, 'Balance from ico partcipation wrong amount')
    assert.equal(balance3.toNumber(), 830 * 10 ** 18, 'Balance from ico partcipation wrong amount')
    assert.equal(balance4.toNumber(), 760 * 10 ** 18, 'Balance from ico partcipation wrong amount')
    assert.equal(balance5.toNumber(), 710 * 10 ** 18, 'Balance from ico partcipation wrong amount')
    assert.equal(balance6.toNumber(), 640 * 10 ** 18, 'Balance from ico partcipation wrong amount')
  })

  it('Correct mixed calculation and distribution', async function () {
    await mineBlock()
    let curTime = await getTime()
    let cs = await ICO.new(curTime + 20, curTime + days12 + 300, accounts[0], {from: accounts[0]})
    let token = Token.at(await cs.token())

    await timeTravel(100)

    await web3.eth.sendTransaction({from: accounts[1], to: cs.address, value: 10 * 10 ** 18, gas: 400000})
    let contrib1 = await cs.contributions(accounts[1])
    await timeTravel(day * 2)
    await web3.eth.sendTransaction({from: accounts[2], to: cs.address, value: 10 * 10 ** 18, gas: 400000})
    let contrib2 = await cs.contributions(accounts[2])

    assert.equal(contrib1.toNumber(), 20 * 10 ** 18, 'Contribution preico wrong amount')
    assert.equal(contrib2.toNumber(), 19 * 10 ** 18, 'Contribution preico wrong amount')

    await timeTravel(day * 10)
    await cs.setBaseRate(100, {from: accounts[0]})
    await timeTravel(400)

    await web3.eth.sendTransaction({from: accounts[1], to: cs.address, value: 10 * (10 ** 18), gas: 400000})
    await timeTravel(day * 5)
    await web3.eth.sendTransaction({from: accounts[2], to: cs.address, value: 10 * 10 ** 18, gas: 400000})

    await timeTravel(day * 25)

    let balance1 = await token.balanceOf(accounts[1])
    let balance2 = await token.balanceOf(accounts[2])

    assert.equal(balance1.toNumber(), 1000 * 10 ** 18, 'Balance from ico partcipation wrong amount')
    assert.equal(balance2.toNumber(), 900 * 10 ** 18, 'Balance from ico partcipation wrong amount')

    await cs.claimTokens({from: accounts[1]})
    await cs.claimTokens({from: accounts[2]})

    assert.equal((await cs.tokenValue()).toNumber(), 6410256, 'Wrong pre-ico token value calculated')

    let claimedBalance1 = await token.balanceOf(accounts[1])
    let claimedBalance2 = await token.balanceOf(accounts[2])

    assert.approximately(claimedBalance1.toNumber(), contrib1.toNumber() * 6410256 + balance1.toNumber(), claimedBalance2.toNumber() * 0.001, 'Balance wrong after claiming')
    assert.approximately(claimedBalance2.toNumber(), contrib2.toNumber() * 6410256 + balance2.toNumber(), claimedBalance2.toNumber() * 0.001, 'Balance wrong after claiming')
  })
})
