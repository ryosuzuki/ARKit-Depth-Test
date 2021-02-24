const app = require('express')()
const http = require('http').createServer(app)
const io = require('socket.io')(http)
const bodyParser = require('body-parser')
const jsonParser = bodyParser.json()

app.use(bodyParser.json({
  limit: '500mb'
}))

app.get('/', (req, res) => {
  console.log('get')
  res.sendFile(__dirname + '/index.html')
})

app.post('/', jsonParser, (req, res) => {
  // console.log(req.body)
  try {
    const json = req.body
    io.sockets.emit('json', json)
  } catch (err) {
    console.log(err)
  }
  res.send('ok')
})

io.on('connection', (socket) => {
  console.log('connected')
  socket.on('disconnect', () => {
    console.log('disconnected')
  })
})

http.listen(3000, () => {
  console.log('Connected at 3000')
})