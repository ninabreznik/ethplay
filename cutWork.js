const fs = require("fs");
const crypto = require('crypto');
const path = require("path");
const hypertrie = require("hypertrie")
const SDK = require('dat-sdk')
const { Hypercore } = SDK()
const Discovery = require('hyperdiscovery')
const blake = require('blakejs')
const db = hypertrie('./trie.db', { valueEncoding: 'json' })
const Promise = require('bluebird')
const cmd = require('node-cmd')
// const tree = require('tree-node-cli');
const getAsync = Promise.promisify(cmd.get, { multiArgs: true, context: cmd })


const cutWork = async (workList) => {
    const workSize = 100

    const folderHash = await generateToken('undersourcecode')

    const saveKeyToJson = []
    const mkPath = path.resolve(`sourcecode/${folderHash}`)

    await mkdirFn(mkPath)
    for (const filePath of workList) {
        const file = await fs.readFileSync(filePath, { encoding: 'utf8' })
        const fileObj = JSON.parse(file)
        if (fileObj.sourceCode) {
            //hash sourceCode become path
            const sourceCodeHash = await generateToken(fileObj.sourceCode)
            if (sourceCodeHash != null) {
                var filedir = path.resolve(`sourcecode/${folderHash}/${sourceCodeHash}`);

                await mkdirFn(filedir)
                try {
                    //createContact
                    await fs.writeFileSync(`${filedir}/source.sol`, fileObj.sourceCode, { encoding: 'utf8' })
                    const address = fileObj.address
                    await mkdirFn(`${filedir}/${address}`)
                    await fs.writeFileSync(`${filedir}/${address}/contract.json`, JSON.stringify(fileObj), { encoding: 'utf8' })
                    saveKeyToJson.push({
                        key: address,
                        value: {
                            sourceAbsoultePath: `${filedir}/source.sol`,
                            contractAbsoultePath: `${filedir}/${address}/contract.json`,
                            sourcePath: `${folderHash}/${address}/source.sol`,
                            contractPath: `${folderHash}/${address}/contract.json`
                        }
                    })

                    //hypertrie here
                    // db.put(address, { address, sourceCodeHash }, function (err, data) {
                    //     db.get(address, function (err, node) { console.log('node', node) })
                    // })
                    if (sourceCodeHash != null) { saveKeyToJson.push({ key: address, }) }
                } catch (err) {
                    console.log('save source.sol have question', err)
                }
            }
        }
    }


    const keyPath = path.resolve(`keypath`);
    const saveKeyToJsonStr = JSON.stringify(saveKeyToJson)

    // await fs.writeFileSync(`${keyPath}/allKey.json`, saveKeyToJsonStr, { encoding: 'utf8' })
    // const result = await getAsync(`tar -zcvf ${keyPath}/allKey.tar ${keyPath}/allKey.json `)
    //change to save to  key
    db.ready(() => {
      const discovery = Discovery(db)
      const url = `dat://${db.key.toString('hex')}`
      // When you find a new peer, tell them about your core
      discovery.add(db)
      // localStorage.setItem('trie_url', url)
      console.log('Dat address', url)
      db.put(folderHash, saveKeyToJsonStr, (err) => {
        if (err) console.log('Error writing', err.message)
      //  else console.log('wrote', folderHash, '-', saveKeyToJsonStr)

        db.get('16238cc7c846ef7e27a3d084ef7c679a36f5b820c3d9b079e24a2d75e7787a64', (err, res) => {
          console.log('Query', res)
        })
        // db.list('', (err, results) => {
        // 	if(err) return log('Error reading from trie', err.message)
        // 	for(let {key, value} of results) {
      	// 	console.log('LIST:', key, 'value:', Buffer.from(value).toString('utf8'))
        // 	}
        // })
      })
      // await db.put(folderHash, ["source.sol", "contract/"])
      //  console.log('result', result)
    })


}

const mkdirFn = async (filedir) => {
    try {
        await fs.readdirSync(filedir)
    } catch (err) {
        console.log('no dir ', err)
        try {
            await fs.mkdirSync(filedir)
        } catch (err) {
            console.log('mkdirSync', err)
        }
    }
}


async function generateToken(sourceCodeString, opts) {
    //hash way1
    //const token = crypto.createHash("sha1").update(sourceCodeString).digest("hex");
    //hash way2
    let token = ''
    //   if (opts === 'blake2') { token = blake.blake2b(sourceCodeString) }
    //if (opts === '') {
    token = blake.blake2sHex(sourceCodeString)
    //}


    //   console.log(token);
    return token;
}
module.exports = cutWork
