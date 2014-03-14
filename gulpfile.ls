!function exportedTasksDefinedBeginsHere
  gulp.task 'publish' <[ publish:lib publish:changelog ]>
/*
 * Implementation details
 */
require! {
  gulp
  'gulp-util'
  'gulp-uglify'
  'gulp-bump'
  'gulp-rename'
  'gulp-conventional-changelog'
}
require! {
  './lib/gulpfile'
}
/*
 * publish tasks
 */
gulp.task 'publish:bump' ->
  return gulp.src  <[
    package.json
    bower.json
  ]>
  .pipe gulp-bump gulp-util.env{type or 'patch'}
  .pipe gulp.dest '.'

gulp.task 'publish:lib' <[ publish:bump ]> ->
  return gulpfile!
  .pipe gulp.dest 'vendor/assets/javascripts'
  .pipe gulp.dest '.'
  .pipe gulp-uglify preserveComments: 'some'
  .pipe gulp-rename extname: '.min.js'
  .pipe gulp.dest '.'

gulp.task 'publish:changelog' <[ publish:bump ]> ->
  return gulp.src <[ package.json CHANGELOG.md ]>
  .pipe gulp-conventional-changelog!
  .pipe gulp.dest '.'
# define!
exportedTasksDefinedBeginsHere!
