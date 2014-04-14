require! {
  gulp
}
require! {
  '../client/gulpfile'
  '../config'
}

gulp.task 'server' <[ client ]> ->
  return require './index' if config.env.is 'production'

  require('gulp-nodemon') do
    script: './server/index.ls'
    execMap: ls: 'lsc'
    ignore: './tmp/**'

