Meteor.methods
	addUserToRoomFromAPI: (roomData , userData ) ->
		#console.log roomData  , '=================================================================' , userData
		if not userData
			throw new Meteor.Error 'error-invalid-user', 'Invalid user', { method: 'addUserToRoom' }

		fromId = roomData.u._id
	 console.log fromId 
 	#console.log roomData , '@@@@@@@@@@@@@@@@@@@@@@' , roomData._id
	 room = RocketChat.models.Rooms.findOneById roomData._id
  #console.log room , '&&&&&&&&&&&&&&&&&&&&&&&&&&&&' , userData.username
  console.log(room.usernames.indexOf(userData.username))

		# if room.username isnt Meteor.user().username and room.t is 'c'
	 console.log fromId
		if not RocketChat.authz.hasPermission(fromId, 'add-user-to-room', room._id)
			throw new Meteor.Error 'error-not-allowed', 'Not allowed', { method: 'addUserToRoom' }

		if room.t is 'd'
			throw new Meteor.Error 'error-cant-invite-for-direct-room', 'Can\'t invite user to direct rooms', { method: 'addUserToRoom' }
  
		# verify if user is already in room
		if room.usernames.indexOf(userData.username) isnt -1
			#console.log(room.usernames , '[]' ,userData.username )
			return

		newUser = RocketChat.models.Users.findOneByUsername userData.username

		RocketChat.models.Rooms.addUsernameById roomData._id, userData.username

		now = new Date()

		RocketChat.models.Subscriptions.createWithRoomAndUser room, newUser,
			ts: now
			open: true
			alert: true
			unread: 1

		fromUser = RocketChat.models.Users.findOneById fromId
		RocketChat.models.Messages.createUserAddedWithRoomIdAndUser roomData._id, newUser,
			ts: now
			u:
				_id: fromUser._id
				username: fromUser.username

		return true
