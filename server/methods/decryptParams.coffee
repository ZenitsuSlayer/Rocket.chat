Meteor.methods
 decryptParams: (text) ->
  crypto = Npm.require('crypto')
  find = ' '
  re = new RegExp(find, 'g')
  text = text.replace(re, '+')
  console.log text
  algorithm = 'aes-256-ctr'
  password = 'd6F3Efeqd6F3Efeqd6F3Efeqd6F3Efeq'
  iv = '1234567890123456'
  decipher = crypto.createDecipheriv(algorithm, password , iv)
  dec = decipher.update(text, 'base64', 'utf8')
  dec += decipher.final('utf8')
  console.log dec
  dec
