import fs from 'fs'
import path from 'path'
let workList: any = []
const fileDisplay = async (filePath: string) => {

    const dirList = await fs.readdirSync(filePath, { encoding: 'utf8' })
    for (var k of dirList) {

        var filedir = path.join(filePath, k);
        const stat = fs.statSync(filedir)
        if (stat.isDirectory()) { await fileDisplay(filedir) }
        if (stat.isFile()) {
            workList.push(filedir)
        }
    }
    //console.log('workList', workList.length)
    return workList;
}

export default fileDisplay