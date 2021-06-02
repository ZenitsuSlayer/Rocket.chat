FlowRouter.route '/login/api/:email/:pass', action: (params, queryParams) ->
  Meteor.loginWithPassword params.email, params.pass, FlowRouter.go 'home'  ,(error) ->
  if error
    console.log error.reason
  else
    FlowRouter.go 'home'