const autoInjectDSL = <[
       $q  $parse  $immediate  Firebase  FirebaseUrl  FirebaseSimpleLogin
]> ++ ($q, $parse, $immediate, Firebase, FirebaseUrl, FirebaseSimpleLogin) ->
  const FIREBASE_QUERY_KEYS = <[limit startAt endAt]>

  const createFirebaseFrom = (queryVars) ->
    const {url} = queryVars
    firenode = new Firebase if url.substr(0, 4) is 'http'
      url
    else
      FirebaseUrl + url
    for key in FIREBASE_QUERY_KEYS when queryVars[key]
      firenode = firenode[key] ...that
    firenode

  for type in [type for type of DSLs]
    DSLs[type] = DSLs[type] $parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom

  const dslResolved = !($scope, dsls) -->
    for name, dsl of dsls
      const assign = $parse name .assign
      dsl._build $scope, bind void, assign, $scope
        
  return ($scope) ->
    const deferred = $q.defer!
    const {promise} = deferred
    delete! deferred.promise
    promise.then dslResolved($scope)
    deferred

const CompactFirebaseSimpleLogin = FirebaseSimpleLogin || noop

angular.module 'angular-on-fire' <[]>
.value {FirebaseUrl: 'https://YOUR_FIREBASE_NAME.firebaseIO.com/', Firebase}
.service {fireAuthDSL: FireAuthDSL, fireObjectDSL: FireObjectDSL, fireCollectionDSL: FireCollectionDSL}
.factory {autoInjectDSL} 
.config <[
        $provide  $injector
]> ++ !($provide, $injector) ->
  unless $injector.has \$immediate
    /*
    an workaround for $immediate implementation, for better scope $digest performance,
    please refer to `angular-utils`
    */
    $provide.factory \$immediate <[$timeout]> ++ identity
  return if $injector.has \FirebaseSimpleLogin 
  #
  # Conditionally inject FirebaseSimpleLogin
  #
  $provide.value \FirebaseSimpleLogin CompactFirebaseSimpleLogin
