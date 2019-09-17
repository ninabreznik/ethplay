const hypertrie = require('hypertrie')
var net = require('net')
const db = hypertrie('./clientTrie.db', { valueEncoding: 'json' })
//const Stream = require('stream')





var temp = []
conn = net.createConnection(10000, 'localhost');

conn.on('connect', function () {
    console.log('connect to server (register)');
    // conn.write(Buffer.from([0])); // give me data  when I connect
    conn.write(Buffer.from([0]))

});

conn.on('data', function (data) {
    //test1
    //  console.log('get api server get data: ---->', data.toString());
    //let obj = JSON.parse(data.toString())    
    let dataX = data.toString()
    recordData(dataX)

})
let index = 0
const recordData = (data) => {

    //db.put(data.key, data.value)
}

conn.on('end', function (data) {
    console.log('finiendsh');
})

















// writableStream.end()

// try {
//     var socket = socket.connect(10000, (err) => {
//         if (err) {
//             console.log('err1', err)
//             return
//         }
//         //socket.pipe(readableStream).pipe(writableStream).pipe(socket)
//         // socket.on('data', (data) =>
//         //     console.log('data', data))
//         // console.log('connect success')
//     })
// } catch (err) {
//     console.log('err2', err)
// }
