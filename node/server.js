const app = require('express')()
const http = require('http').createServer(app)
const io = require('socket.io')(http)

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html')
})

io.on('connection', (socket) => {
  console.log('connected')

  socket.on('test', (msg) => {
    console.log(msg)
  })

  socket.on('disconnect', () => {
    console.log('disconnected')
  })
})

http.listen(3000, () => {
  console.log('Connected at 3000')
})