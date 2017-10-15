module.exports = async function (callback) {
  let web3ErrorThrown = false
  try {
    await callback()
  } catch (error) {
    if (error.message.search('invalid opcode')) web3ErrorThrown = true
  }
  assert.ok(web3ErrorThrown, 'Transaction should fail')
}
