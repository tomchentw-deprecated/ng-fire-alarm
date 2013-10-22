DSLs.auth = ($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom) ->

  return !($scope, {root, next}) ->
    const ref = new FirebaseSimpleLogin new Firebase(root), !(error, auth) ~>
      <~! $immediate
      next copy if error or not auth then {} else auth, ^^ref
