Meteor.publish 'settings', ->
	console.log '[publish] settings'.green
	
	if this.userId
		user = Meteor.users.findOne this.userId
		if user.admin
			return Settings.find()

	return Settings.find { where: 'client' }, { fields: _id: 1, value: 1}