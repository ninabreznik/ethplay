import fs from "fs";
// import crypto from 'crypto'

// const hash = crypto.createHash('md5');
import hash from 'object-hash'


const cutWork = async (workList: any) => {
    const workSize = 100
    ///    console.log('1', Math.ceil(workList.length / workSize))
    for (const filePath of workList) {
        const file: any = await fs.readFileSync(filePath, { encoding: 'utf8' })
        const fileObj = JSON.parse(file)
        if (fileObj.sourceCode) {
            console.log('fileObj', hash(fileObj.sourceCode, { algorithm: 'md5', encoding: 'base64' }))
        }


        //await hash.update(fileObj.sourceCode)
        //console.log(hash.digest('hex') + '/n');
    }

}


export default cutWork