Meteor.methods addPingToFirebase: (m,u) ->
  room = RocketChat.models.Rooms.findOneById(m.rid)
  console.log '------Triggering ping to FIrebase------'
  console.log m
  console.log '---------------For Room----------------'
  console.log room
  console.log '---------------Ping To-----------------'
  array = room.usernames
  index = array.indexOf(u)
  array.splice index, 1
  console.log array
  console.log '---------------Notifications Id----------------'
  array.forEach (entry) ->
    user = RocketChat.models.Users.findByUsername(entry).fetch()
    console.log user[0]._id 
    if user.length > 0
      FirebaseClient = Npm.require('firebase-client')
      firebase = new FirebaseClient(url: 'https://vendoradvisor-4df3f.firebaseio.com/')
      firebase.push('chat', uId: user[0]._id ).then (body) ->
        console.log body
    return
  true