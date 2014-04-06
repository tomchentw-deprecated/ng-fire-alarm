require! {
  Q: q
  connect
}
require! {
  '../config'
}

module.exports = ->
  const deferred = Q.defer!

  connect!
    ..use require('connect-livereload')! unless config.env.is 'production'

    ..use connect.static 'public' maxAge: Infinity
    ..use connect.static 'tmp/public' unless config.env.is 'production'

    ..listen config.port.server, !->
      console.log "connect started at port #{ config.port.server }" &
      deferred.resolve!

  deferred.promise
