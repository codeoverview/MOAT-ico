const mineBlock = require('./mineBlock')

const timeJump = function (time) {
  return new Promise((resolve, reject) => {
    // const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:9545')) // Hardcoded development port
    // console.log(web3.currentProvider)
    web3.currentProvider.sendAsync({
      jsonrpc: '2.0',
      method: 'evm_increaseTime',
      params: [time], // 86400 is num seconds in day
      id: new Date().getTime()
    }, (err, result) => {
      if (err) { return reject(err) }
      return resolve(result)
    })
  })
}



async function timeTravel (time) {
  await timeJump(time)
  await mineBlock()
  return true
}

module.exports = timeTravel
