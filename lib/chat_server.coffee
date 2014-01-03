socketio = require('socket.io')
io = null
guestNumber = 1
nickNames = []
namesUsed = []
currentRoom = {}

exports.listen = (server) ->
  io = socketio.listen(server)
  io.set 'log level', 1

  io.sockets.on 'connection', (socket) ->
    guestNumber = assignGuestName(socket, guestNumber, nickNames, namesUsed)
    joinRoom socket, 'Lobby'
    handleMessageBroadcasting socket, nickNames
    handleNameChangeAttempts socket, nickNames, namesUsed
    handleRoomJoining socket
    socket.on 'rooms', ->
      socket.emit 'rooms', io.sockets.manager.rooms
    handleClientDisconnection socket, nickNames, namesUsed

assignGuestName = (socket, guestNumber, nickNames, namesUsed) ->
  name = "Guest #{guestNumber}"
  nickNames[socket.id] = name
  socket.emit 'nameResult',
    success: true,
    name: name
  namesUsed.push name
  ++guestNumber

joinRoom = (socket, room) ->
  socket.join room
  currentRoom[socket.id] = room
  socket.emit 'joinResult', { room }
  socket.broadcast.to(room).emit 'message',
    text: "#{nickNames[socket.id]} has joined #{room}."

  usersInRoom = io.sockets.clients(room)
  if usersInRoom.length > 1
    usersInRoomSummary = "Users currently in #{room}: "
    for index in usersInRoom
      userSocketId = usersInRoom[index].id
      if userSocketId isnt socket.id
        if index > 0
          usersInRoomSummary += ', '
        usersInRoomSummary += nickNames[userSocketId]
    usersInRoomSummary += '.'
    socket.emit 'message', text: usersInRoomSummary

handleNameChangeAttempts = (socket, nickNames, namesUsed) ->
  socket.on 'nameAttempt', (name) ->
    if name.indexOf('Guest') is 0
      socket.emit 'nameResult',
        success: false,
        message: 'Names cannot begin with "Guest".'
    else
      if namesUsed.indexOf(name) is -1
        previousName = nickNames[socket.id]
        previousNameIndex = namesUsed.indexOf(previousName)
        namesUsed.push name
        nickNames[socket.id] = name
        delete namesUsed[previousNameIndex]
        socket.emit 'nameResult',
          success: true,
          name: name
        socket.broadcast.to(currentRoom[socket.id]).emit 'message',
          text: "#{previousName} is now known as #{name}."
      else
        socket.emit 'nameResult',
          success: false,
          message: 'That name is already in use.'

handleMessageBroadcasting = (socket) ->
  socket.on 'message', (message) ->
    socket.broadcast.to(message.room).emit 'message',
      text: "#{nickNames[socket.id]}: #{message.text}"

handleRoomJoining = (socket) ->
  socket.on 'join', (room) ->
    socket.leave(currentRoom[socket.id])
    joinRoom(socket, room.newRoom)

handleClientDisconnection = (socket) ->
  socket.on 'disconnect', ->
    nameIndex = namesUsed.indexOf(nickNames[socket.id])
    delete namesUsed[nameIndex]
    delete nickNames[socket.id]
