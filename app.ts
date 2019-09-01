import fileDisplay from './fileDisplay'
import path from 'path'


(async () => {
    var filePath = path.resolve('./evm-smart-contracts/contracts');

    const workList = await fileDisplay(filePath)


    console.log('workList  ', workList.length)
})()

