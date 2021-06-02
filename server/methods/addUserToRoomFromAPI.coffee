Meteor.methods
	addUserToRoomFromAPI: (roomData , userData ) ->
		if not userData
			throw new Meteor.Error 'error-invalid-user', 'Invalid user', { method: 'addUserToRoom' }

		roomAdminId = roomData.u._id

	 room = roomData
		# if room.username isnt Meteor.user().username and room.t is 'c'
	 if not RocketChat.authz.hasPermission(roomAdminId , 'add-user-to-room', room._id)
			throw new Meteor.Error 'error-not-allowed', 'Not allowed', { method: 'addUserToRoomFromAPI' }
    

		if room.t is 'd'
			throw new Meteor.Error 'error-cant-invite-for-direct-room', 'Can\'t invite user to direct rooms', { method: 'addUserToRoomFromAPI' }

		# verify if user is already in room



		if room.usernames.indexOf(userData.username) isnt -1
			return true
	 
		newUser = RocketChat.models.Users.findOneByUsername userData.username
   
	
		RocketChat.models.Rooms.addUsernameById roomData._id , userData.username
  
		now = new Date()
	 

		RocketChat.models.Subscriptions.createWithRoomAndUser room, newUser,
			ts: now
			open: true
			alert: true
			unread: 1
	 
		fromUser = RocketChat.models.Users.findOneById roomAdminId


		RocketChat.models.Messages.createUserAddedWithRoomIdAndUser room._id , newUser,
			ts: now
			u:
				_id: fromUser._id
				username: fromUser.username

		return true
