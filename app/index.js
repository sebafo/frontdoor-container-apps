const express = require('express');

const app = express();

app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

var listener = app.listen(process.env.PORT || 3000, function() {
    console.log('App is listening on port ' + listener.address().port);
});