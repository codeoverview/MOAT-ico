const getTime = function () {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync({
      jsonrpc: '2.0',
      method: 'eth_getBlockByHash',
      params: ['latest', true] // 86400 is num seconds in day
    }, (err, result) => {
      if (err) { return reject(err) }
      return resolve(parseInt(result.result.timestamp, 16))
    })
  })
}

module.exports = getTime