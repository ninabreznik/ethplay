const hypertrie = require('hypertrie')
const db = hypertrie('./trie.db', { valueEncoding: 'json' })
const allKey = require('./keypath/allKey.json')


//console.log('allKey', allKey)
const beginPathKey = '16238cc7c846ef7e27a3d084ef7c679a36f5b820c3d9b079e24a2d75e7787a64'
//get beginPathValue ["./source.sol", "./contract/"]
db.get(beginPathKey, '', function (err, beginPathValue) {
    //import json
    db.batch(allKey, function (batcherr, batchnode) {
        db.createReadStream()
            .on('data', data => {
                const key = data['key']
                db.get(key, function (err, node) {
                    // console.log('node', node)

                    if (node['value.address']) {
                        const address = node['value.address']
                        let obj = {
                            sourcePath: `${beginPathKey}/${key}/${beginPathValue.value[0]}`,
                            contractPath: `${beginPathKey}/${key}/${address}/${beginPathValue.value[1]}`
                        }

                        console.log('obj', obj)
                    }

                })
            })
            .on('end', _ => console.log('(end)'))

    })
})
