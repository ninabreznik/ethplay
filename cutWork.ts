import fs from "fs";
// import crypto from 'crypto'
import path from 'path'

// const hash = crypto.createHash('md5');
import hash from 'object-hash'


const cutWork = async (workList: any) => {
    const workSize = 100
    ///    console.log('1', Math.ceil(workList.length / workSize))
    for (const filePath of workList) {
        const file: any = await fs.readFileSync(filePath, { encoding: 'utf8' })
        const fileObj = JSON.parse(file)
        if (fileObj.sourceCode) {
            // console.log('fileObj', hash(fileObj.sourceCode, { algorithm: 'md5', encoding: 'base64' }))
            let dirName = hash(fileObj.sourceCode)
            var filedir = path.resolve(`sourcecode/${dirName}`);
            await mkdirFn(filedir)
            // if (!stat.) {
            try {
                await fs.writeFileSync(`${filedir}/source.sol`, fileObj.sourceCode, { encoding: 'utf8' })
            } catch (err) {
                console.log('save source.sol have question', err)
            }


            // }
        }


        //await hash.update(fileObj.sourceCode)
        //console.log(hash.digest('hex') + '/n');
    }

}

const mkdirFn = async (filedir: string) => {
    try {
        await fs.readdirSync(filedir)
    } catch (err) {
        console.log('no dir ')
        try {
            console.log('make dir ')

            await fs.mkdirSync(filedir)
        } catch (err) {
            console.log('err')
        }
    }
}


export default cutWork