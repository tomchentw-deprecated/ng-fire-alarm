/* declare as app module dependency. */
@demo = angular.module \demo <[ui.bootstrap angular-on-fire]>
.value {FirebaseUrl: \https://angular-on-fire.firebaseio.com}
.filter 'njson' ->
  const {getPrototypeOf} = Object
  const {stringify} = JSON
  const {toJson, isObject, isArray, extend} = angular
  return toJson unless getPrototypeOf? && stringify?
  const extendRef = {$ref: '[object Function]'}

  function nativeToJsonFilter
    return unless isObject it

    stringify if isArray it
      for item in it
        const args = [if isArray item then [] else {}, getPrototypeOf(item)] ++ [item, extendRef]
        extend ...args
    else
      extend {}, getPrototypeOf(it), it, extendRef
    , null, 2