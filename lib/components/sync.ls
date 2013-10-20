const autoRejectPool = <[$q]> ++ ($q) ->
  const destroyEvent = '$destroy'

  ($scope) ->
    const deferred = $q.defer!
    const {promise} = deferred
    delete! deferred.promise
    promise.then !(autoRejectValues) ->
      $scope.$on destroyEvent !->
        for key, value of autoRejectValues
          value.reject destroyEvent
      $scope <<< autoRejectValues
    deferred

class FireSync
  

const fireSync = <[$q $immediate]> ++ ($q, $immediate) ->

  ->
    const result = $q.defer!
    const promise = result.promise
    const reject = $q.defer!
    




    promise <<< reject{reject}



angular.module 'angular-on-fire' <[]>
.factory {fireSync} 

