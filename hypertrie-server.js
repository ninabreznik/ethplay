const hypertrie = require('hypertrie')
var net = require('net')

const db = hypertrie('./trie.db', { valueEncoding: 'json' })
const Readable = require('stream').Readable
const beginPathKey = '16238cc7c846ef7e27a3d084ef7c679a36f5b820c3d9b079e24a2d75e7787a64'
var index = 0


// const reader = new Readable({
//     objectMode: true,
//     read: function (size) {
//         //write hy db data here
//         ///   console.log('fake data wait for read')
//         // console.log('hypertrie db data', data)
//         // var chunk = (index < 1000) ? {
//         //     type: 'put',
//         //     key: data['key'],
//         //     value: data['value']
//         // } : null
//         //this.push(value)
//     },
// })

// reader.on('readable', async (data) => {
//     readable.setEncoding('utf8');
//     for await (const chunk of readable) {
//         data += chunk;
//     }
//     console.log(data);
// });
// reader.on('data', () => {
//     console.log('datadatadata')
// })
// reader.on('end', () => { console.log('read end ') })
// reader.pipe(stream)

// const steam = db.createWriteStream()
//     .on('open', () => console.log('open'))
//     .on('data', data => {
//         console.log('run db key', data.key)
//         socket.write(data)
//     })
//     .on('end', _ => console.log('(end)'))
//     .on('finish', function (err) {
//         console.log('finish')
//         console.log('err', err)
//     })

var server = net.createServer(function (socket) {

    const connectSrcIp = socket.remoteAddress;
    console.log('client connectSrcIp', connectSrcIp)

    socket.on('data', function (data) {
        //frist time give key then next time use key to get valye
        //------------
        //test1
        db.createReadStream()
            .on('data', data => socket.write(
                JSON.stringify(data)
            ))
            .on('end', _ => {

                // socket.write(';')
                console.log('(end)')
            })
    });

    // try {
    //     socket.pipe(reader, { end: false }).pipe(socket)
    // } catch (err) {
    //     console.log('err', err)
    // }
})

server.on('error', (err) => {
    console.log('server err', err)
})
server.listen(10000, () => {
    console.log('port 10000 is open wait for link')
})