const fileDisplay = require('./fileDisplay');
const path = require('path');
const cutWork = require('./cutWork');

(async () => {
    var filePath = path.resolve('./evm-smart-contracts/contracts');

    const workList = await fileDisplay(filePath)
    console.log('WORKLIST')
    console.log(workList)
    //cut work 100 times


    await cutWork(workList)
    //console.log('workList  ', workList.length)
})()
