DSLs.flatten = ($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom) ->

  return !($scope, {results, next}) ->
    const values = []
    for result in results
      (value, key) <-! forEach result
      return if key.match /^\$/
      value = regularizeObject value
      value.$name = key
      value.$index = -1+values.push value

    $immediate !-> next values