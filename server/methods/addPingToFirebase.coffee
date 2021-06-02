Meteor.methods addPingToFirebase: (m) ->
  FirebaseClient = undefined
  firebase = undefined
  room = undefined
  console.log '------Triggering ping to FIrebase------'
  console.log m
  console.log '---------------------------------------'
  room = RocketChat.models.Rooms.findOneById(m.rid)
  console.log room
  room.usernames.forEach (entry) ->
    console.log entry
    user = RocketChat.models.Users.findByUsername(entry).fetch()
    FirebaseClient = Npm.require('firebase-client')
    firebase = new FirebaseClient(url: 'https://vendoradvisor-4df3f.firebaseio.com/')
    firebase.push('chat', uId: user[0]._id ).then (body) ->
      console.log body
    return
  true