const mineBlock = function () {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync({
      jsonrpc: '2.0',
      method: 'evm_mine'
    }, (err, result) => {
      if (err) { return reject(err) }
      return resolve(result)
    })
  })
}

async function mineBlocks (blocks = 0) {
  let mined = 0
  while (mined < blocks) {
    await mineBlock()
    mined = mined + 1
  }
  return true
}

module.exports = mineBlocks
