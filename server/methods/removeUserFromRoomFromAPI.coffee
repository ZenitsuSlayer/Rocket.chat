Meteor.methods
	removeUserFromRoomFromAPI: (roomData , userData) ->
		if not Meteor.userId()
			throw new Meteor.Error 'error-invalid-user', 'Invalid user', { method: 'removeUserFromRoom' }

		fromId = Meteor.userId()

		unless RocketChat.authz.hasPermission(fromId, 'remove-user', roomData._id)
			throw new Meteor.Error 'error-not-allowed', 'Not allowed', { method: 'removeUserFromRoom' }

		room = RocketChat.models.Rooms.findOneById roomData._id

		if userData.username not in (room?.usernames or [])
			throw new Meteor.Error 'error-user-not-in-room', 'User is not in this room', { method: 'removeUserFromRoom' }

		removedUser = RocketChat.models.Users.findOneByUsername userData.username

		RocketChat.models.Rooms.removeUsernameById roomData._id, userData.username

		RocketChat.models.Subscriptions.removeByRoomIdAndUserId roomData._id, removedUser._id

		if room.t in [ 'c', 'p' ]
			RocketChat.authz.removeUserFromRoles(removedUser._id, ['moderator', 'owner'], roomData._id)

		fromUser = RocketChat.models.Users.findOneById fromId
		RocketChat.models.Messages.createUserRemovedWithRoomIdAndUser roomData._id, removedUser,
			u:
				_id: fromUser._id
				username: fromUser.username

		return true
