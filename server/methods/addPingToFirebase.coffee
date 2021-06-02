Meteor.methods addPingToFirebase: (m) ->
  FirebaseClient = undefined
  firebase = undefined
  room = undefined
  console.log '------Server Side------', m
  room = RocketChat.models.Rooms.findOneById(m.rid)
  console.log room
  room.usernames.forEach (entry) ->
    console.log entry
    users = RocketChat.models.Users.findByUsername(entry).fetch()
    FirebaseClient = Npm.require('firebase-client')
    firebase = new FirebaseClient(url: 'https://vendoradvisor-4df3f.firebaseio.com/')
    firebase.push('chat', username: entry ).then (body) ->
      console.log body
      return
      console.log users
    return
  true