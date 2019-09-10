const hypertrie = require('hypertrie')
const db = hypertrie('./trie.db', { valueEncoding: 'json' })
const allKey = require('./keypath/allKey.json')


const beginPathKey = '16238cc7c846ef7e27a3d084ef7c679a36f5b820c3d9b079e24a2d75e7787a64'
//get beginPathValue ["./source.sol", "./contract/"]
db.get(beginPathKey, function (err, beginPathValue) {
    //import json

    const data = JSON.parse(beginPathValue['value'])
    console.log('beginPathValue', data)

    db.batch(JSON.parse(beginPathValue['value']), function () {
        db.createReadStream()
            .on('data', data => {
                if ((data.key !== '16238cc7c846ef7e27a3d084ef7c679a36f5b820c3d9b079e24a2d75e7787a64') && (data.value != null)) {
                    console.log('data--------->', data)
                    return data
                }
            })
            .on('end', _ => console.log('(end)'))

    })
})
