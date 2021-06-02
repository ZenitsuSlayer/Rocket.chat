# find room
RocketChat.API.v1.addRoute 'room.get', authRequired: true,
	post: ->
		return RocketChat.API.v1.success
			room: RocketChat.models.Rooms.findOne({_id: @bodyParams.id})