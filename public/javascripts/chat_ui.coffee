divEscapedContentElement = (message) ->
  $('<div>').text message

divSystemContentElement = (message) ->
  $('<div>').html "<i>#{message}</i>"

processUserInput = (chatApp, socket) ->
  message = $('#send-message').val()
  systemMessage = null

  if message.charAt(0) is '/'
    systemMessage = chatApp.processCommand(message)
    if systemMessage
      $('#messages').append divSystemContentElement(systemMessage)
  else
    chatApp.sendMessage $('#room').text(), message
    $('#messages').append divEscapedContentElement(message)
    $('#messages').scrollTop $('#messages').prop('scrollHeight')

  $('#send-message').val('')

socket = io.connect()

$ ->
  chatApp = new Chat(socket)

  socket.on 'nameResult', (result) ->
    message = if result.success
      "You are now knows as #{result.name}."
    else
      result.message
    $('#messages').append divSystemContentElement(message)

  socket.on 'joinResult', (result) ->
    $('#room').text result.room
    $('#messages').append divSystemContentElement('Room changed.')

  socket.on 'message', (message) ->
    newElement = $('<div>').text(message.text)
    $('#messages').append newElement

  socket.on 'rooms', (rooms) ->
    $('#room-list').empty()

    for room in rooms
      console.log room
      room = room.substring(1, room.length)
      if room isnt ''
        console.log 'appending'
        $('#room-list').append divEscapedContentElement(room)

    $('#room-list div').on 'click', ->
      chatApp.processCommand "/join #{$(this).text()}"
      $('#send-message').focus()

  setInterval ->
    socket.emit 'rooms'
  , 1000

  $('#send-message').focus()

  $('#send-form').on 'submit', ->
    processUserInput chatApp, socket
    false

