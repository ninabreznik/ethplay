import fileDisplay from './fileDisplay'
import path from 'path'
import cutWork from './cutWork'

(async () => {
    var filePath = path.resolve('./evm-smart-contracts/contracts');

    const workList = await fileDisplay(filePath)

    //cut work 100 times


    await cutWork(workList)
    //console.log('workList  ', workList.length)
})()

