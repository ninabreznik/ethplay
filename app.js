const fileDisplay = require('./fileDisplay');
const path = require('path');
const cutWork = require('./cutWork');

(async () => {
    var filePath = path.resolve('./evm-smart-contracts/contracts');
    const workList = await fileDisplay(filePath)
    console.log(`WORKLIST (length):${workList.length}`)
    console.log(workList)
    await cutWork(workList)
})()
