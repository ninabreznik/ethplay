const fs = require("fs");
const crypto = require('crypto');
const path = require("path");
const hypertrie = require("hypertrie");
const blake = require('blakejs')
const db = hypertrie('./trie.db', { valueEncoding: 'json' })
const Promise = require('bluebird')
const cmd = require('node-cmd')
// const tree = require('tree-node-cli');
const getAsync = Promise.promisify(cmd.get, { multiArgs: true, context: cmd })





const cutWork = async (workList) => {
    const workSize = 100

    const folderHash = await generateToken('undersourcecode')

    await db.put(folderHash, ["source.sol", "contract/"])
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
                    saveKeyToJson.push({ key: address })

                    //hypertrie here                                         
                    db.put(address, {
                        address,
                        sourceCodeHash
                    }, function (err, data) {
                        //console.log(data)
                        db.get(address, function (err, node) {
                            console.log('node', node)
                        })
                    })
                    if (sourceCodeHash != null) { saveKeyToJson.push({ key: address, }) }
                } catch (err) {
                    console.log('save source.sol have question', err)
                }
            }
        }
    }


    const keyPath = path.resolve(`keypath`);
    const saveKeyToJsonStr = JSON.stringify(saveKeyToJson)
    //console.log('saveKeyToJsonStr', saveKeyToJsonStr)
    await fs.writeFileSync(`${keyPath}/allKey.json`, saveKeyToJsonStr, { encoding: 'utf8' })
    const result = await getAsync(`tar -zcvf ${keyPath}/allKey.tar ${keyPath}/allKey.json `)
    //  console.log('result', result)

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