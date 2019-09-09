const fs = require("fs");
const crypto = require('crypto');
const path = require("path");
const hypertrie = require("hypertrie");
const blake = require('blakejs')
const db = hypertrie('./trie.db', { valueEncoding: 'json' })

const cutWork = async (workList) => {
    const workSize = 100
    ///    console.log('1', Math.ceil(workList.length / workSize))
    const saveKeyToJson = []
    for (const filePath of workList) {
        const file = await fs.readFileSync(filePath, { encoding: 'utf8' })
        const fileObj = JSON.parse(file)
        if (fileObj.sourceCode) {
            const dirName = await generateToken(fileObj.sourceCode)
            if (dirName != null) {

                var filedir = path.resolve(`sourcecode/${dirName}`);
                await mkdirFn(filedir)
                // if (!stat.) {
                try {
                    //createContact

                    await fs.writeFileSync(`${filedir}/source.sol`, fileObj.sourceCode, { encoding: 'utf8' })


                    //const contactName = path.basename(filedir)
                    const contactName = fileObj.address
                    await mkdirFn(`${filedir}/${contactName}`)

                    // delete fileObj.sourceCode
                    //you can add new info here
                    // fileObj['test'] = 'test1'
                    // fileObj['test2'] = 'test2'
                    await fs.writeFileSync(`${filedir}/${contactName}/contract.json`, JSON.stringify(fileObj), { encoding: 'utf8' })

                    // console.log('test', JSON.stringify(fileObj))
                    //console.log('test', fileObj)

                    //await fs.copyFileSync(filePath, `${filedir}/contact.json`)
                    saveKeyToJson.push({ key: contactName })
                    //hypertrie here 
                    db.put(contactName, fileObj.sourceCode, function () {
                        //db.get(contactName, console.log)
                    })
                    if (dirName != null) { saveKeyToJson.push({ key: dirName }) }
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

}

const mkdirFn = async (filedir) => {
    try {
        await fs.readdirSync(filedir)
    } catch (err) {
        // console.log('no dir ')
        try {
            await fs.mkdirSync(filedir)
        } catch (err) {
            console.log('err')
        }
    }
}


async function generateToken(sourceCodeString) {
    //hash way1
    //const token = crypto.createHash("sha1").update(sourceCodeString).digest("hex");
    //hash way2
    const token = blake.blake2sHex(sourceCodeString)
    //console.log(token);
    return token;
}
module.exports = cutWork