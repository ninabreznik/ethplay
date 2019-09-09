const express = require('express');
const app = express();
const Promise = require('bluebird')
const cmd = require('node-cmd')
const tree = require('tree-node-cli');
const path = require('path')
const getAsync = Promise.promisify(cmd.get, { multiArgs: true, context: cmd })
app.use('../etherscan-scraper/sourcecodes/', express.static('dat'));

app.get('/size', async (req, res) => {

    const result = await getAsync('cd ../etherscan-scraper/sourcecodes && du -sh ')
    res.send(result[0])
});

app.get('/count', async (req, res) => {
    const result = await getAsync('ls ../etherscan-scraper/sourcecodes | ls -1 /usr/bin/ | wc -l    ')
    res.send(result[0])
});

app.get('/allkey', async (req, res) => {
    const keyPath = path.resolve(`keypath`);
    res.download(`${keyPath}/allKey.tar`)
});

app.get('/daturl', async (req, res) => {
    res.send('')
});



app.listen(3001, function () {
    console.log('Example app listening on port 3001!');
});