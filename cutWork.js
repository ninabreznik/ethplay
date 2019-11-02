const fs = require("fs");
const crypto = require('crypto');
const path = require("path");
const hypertrie = require("hypertrie")
const SDK = require('dat-sdk')
const { Hypercore } = SDK()
//const Discovery = require('hyperdiscovery')
const blake = require('blakejs')
const db = hypertrie('./trie.db', { valueEncoding: 'json' })

const { inspect } = require('util')
const hyperswarm = require('hyperswarm')
const swarm = hyperswarm({
 announceLocalAddress: true
})


const cutWork = async (workList) => {
  db.ready(() => {
    //const discovery = Discovery(db)
    const key = crypto.createHash('sha256')
    .update('verified-contracts')
    .digest()

    console.log(key.toString('hex'))

    swarm.connectivity((err, capabilities) => {
      console.log('network capabilities', capabilities, err || '')
    })

    swarm.join(key, {
      announce: true,
      lookup: true
    })

    const url = `dat://${db.key.toString('hex')}`
    //discovery.add(db)
    setTimeout(() => console.log('Dat address', url), 10000)
    cutAndSave()
  })
  async function cutAndSave () {
    let sourceCodeHash
    for (const filePath of workList) {
      const file = await fs.readFileSync(filePath, { encoding: 'utf8' })
      const fileObj = JSON.parse(file)
      if (fileObj.sourceCode) {
        sourceCodeHash = await blake.blake2sHex(fileObj.sourceCode)
        saveToTrie(sourceCodeHash, fileObj)
      }
    }
  }
  function saveToTrie (sourceCodeHash, fileObj) {
    const hash = `sourcecode/${sourceCodeHash}.sol`
    const contract = `contract/${fileObj.address}.json`
    db.put(hash, fileObj.sourceCode, (err) => {
      if (err) console.log('Error writing', err.message)
      //else console.log('wrote', hash, ':', fileObj.contractName)
    })
    db.put(contract, fileObj, (err) => {
      if (err) console.log('Error writing', err.message)
      //else console.log('wrote', contract, ':', `JSON for ${fileObj.contractName}`)
    })
  }
}
module.exports = cutWork
