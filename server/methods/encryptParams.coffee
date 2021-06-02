Meteor.methods encryptParams: (text) ->
  algorithm = undefined
  cipher = undefined
  crypto = undefined
  password = undefined
  crypted = undefined
  crypto = Npm.require('crypto')
  algorithm = 'aes-256-ctr'
  password = 'd6F3Efeqd6F3Efeqd6F3Efeqd6F3Efeq'
  iv = '1234567890123456'
  cipher = crypto.createCipheriv(algorithm, password, iv)
  crypted = cipher.update(text, 'utf8', 'base64')
  crypted += cipher.final('base64')
  crypted
