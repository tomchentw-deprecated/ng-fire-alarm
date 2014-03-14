require! {
  connect
}

require! {
  '../config'
}

const server = connect!

unless config.env.is 'production'
  require! 'connect-livereload'
  server.use connect-livereload!

server.use connect.static 'public'
server.use connect.static 'tmp/public'

server.listen config.port.express
