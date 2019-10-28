const fs = require('fs');
const path = require('path');
let workList = []
const fileDisplay = async (filePath) => {
  const dirList = await fs.readdirSync(filePath, { encoding: 'utf8' })
  for (var k of dirList) {
      var filedir = path.join(filePath, k);
      const stat = fs.statSync(filedir)
      if (stat.isDirectory()) { await fileDisplay(filedir) }
      if (stat.isFile()) {
          workList.push(filedir)
      }
  }
  return workList;
}

module.exports = fileDisplay
