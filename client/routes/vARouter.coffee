FlowRouter.route '/login/api/:email/:pass', action: (params, queryParams) ->
  Meteor.loginWithPassword params.email, params.pass, FlowRouter.go 'home'  ,(error) ->
  if error
    console.log error.reason
  else
    FlowRouter.go 'home'


FlowRouter.route '/validate/api', action: (params, queryParams) ->
  console.log queryParams.verify
  username = '' 
  password = ''
  timestamp = ''
  Meteor.call 'decryptParams', queryParams.verify, (error, result) ->
    if not error
       console.log result
       result = result.split('(*)')
       console.log result
       username = result[0]
       password = result[1]
       Meteor.call 'decryptParams', queryParams.token, (error, result) ->
        if not error
          console.log result
          Meteor.loginWithPassword username , password , FlowRouter.go 'home'  ,(error) ->
           if error
            console.log error.reason
        else
          console.log error      
       true
    else
       console.log error      
  return true