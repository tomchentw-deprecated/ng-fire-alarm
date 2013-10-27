DSL.auth = ($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom) ->

  return !($scope, {root, next}) ->
    const simpleLoginRef = new FirebaseSimpleLogin new Firebase(root), !(error, auth) ~>
      auth = {} if error or not auth
      <~! $immediate
      next regularizeAuth auth, simpleLoginRef
