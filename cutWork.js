const fs = require("fs");
const crypto = require('crypto');
const path = require("path");
const hypertrie = require("hypertrie");
const blake = require('blakejs')
const db = hypertrie('./trie.db', { valueEncoding: 'json' })

const cutWork = async (workList) => {
    const workSize = 100
    ///    console.log('1', Math.ceil(workList.length / workSize))
    for (const filePath of workList) {
        const file = await fs.readFileSync(filePath, { encoding: 'utf8' })
        const fileObj = JSON.parse(file)
        if (fileObj.sourceCode) {
            const dirName = await generateToken(fileObj.sourceCode)
            var filedir = path.resolve(`sourcecode/${dirName}`);
            await mkdirFn(filedir)
            // if (!stat.) {
            try {
                //createContact

                await fs.writeFileSync(`${filedir}/source.sol`, fileObj.sourceCode, { encoding: 'utf8' })
                //     await fs.writeFileSync(`${filedir}/contact.json`, JSON.stringify(file), { encoding: 'utf8' })
                await fs.copyFileSync(filePath, `${filedir}/contact.json`)

                db.put(`${filedir}`, fileObj.sourceCode, function () {
                    db.get('hello', console.log)
                })
            } catch (err) {
                console.log('save source.sol have question', err)
            }


            // }
        }



    }

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