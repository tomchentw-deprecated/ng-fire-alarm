require! {
  gulp
}
require! {
  '../client/gulpfile'
  './index'
}

gulp.task 'server' <[ client ]> index
