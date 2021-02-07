const app = require('express')()
const http = require('http').createServer(app)
const io = require('socket.io')(http)

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html')
})

io.on('connection', (socket) => {
  console.log('connected')

  socket.on('test', (msg) => {
    let buffer = Buffer.from(msg)
    let str = buffer.toString('utf8')
    try {
      let json = JSON.parse(str)
      console.log(json)
      io.emit('meshes', json)
    } catch (err) {
      console.log(err)
    }
  })

  socket.on('disconnect', () => {
    console.log('disconnected')
  })
})

http.listen(3000, () => {
  console.log('Connected at 3000')
})