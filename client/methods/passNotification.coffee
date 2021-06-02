Meteor.methods passNotification: (message) ->
  Meteor.call('addPingToFirebase', message)
  console.log ChatSubscription.findByUserId message.u._id
  console.log '-----', 'client side', message, '---------'
