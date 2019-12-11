const fs = require("fs");
const hypertrie = require("hypertrie")
const blake = require('blakejs')
const db = hypertrie('./trie.db', { valueEncoding: 'json' })
const replicate = require('@hyperswarm/replicator')
const hyperswarm = require('hyperswarm')

const swarm = hyperswarm()
var count = 0

const cutWork = async (workList) => {
  db.ready(() => {
    const url = `dat://${db.key.toString('hex')}`
    //discovery.add(db)
    setTimeout(() => console.log('Dat address', url), 10000)
    cutAndSave()
    swarm.join(db.key, {
      live: true,
      lookup: true, // find & connect to peers
      announce: true // optional- announce self as a connection target
    })
    swarm.on('connection', (connection, info) => {
      console.log('new connection!')
      connection.pipe(db.feed.replicate(info.client)).pipe(connection)
    })
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
    //const hash = `sourcecode/${sourceCodeHash}.sol`
      count++
      const i = count.toString().padStart(10, '0')
      // db.put(hash, fileObj.sourceCode, (err) => {
      //   if (err) console.log('Error writing', err.message)
      //   else console.log('wrote', hash, ':', fileObj.contractName)
      // })
    db.put(i, fileObj, (err) => {
      if (err) console.log('Error writing', err.message)
      else console.log('wrote', i, ':', `JSON for ${fileObj.contractName}`)
    })
  }
}
module.exports = cutWork
