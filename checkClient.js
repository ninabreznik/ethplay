const hypertrie = require('hypertrie')
const db = hypertrie('./clientTrie.db', { valueEncoding: 'json' })


db.createReadStream()
    .on('data', data => {
        console.log('data')
    }
    )
    .on('end', _ => console.log('(end)'))


