!function exportedTasksDefinedBeginsHere
  gulp.task 'client' <[ client:html client:css client:js ]> !->
    return if config.env.is 'production'
    livereload.listen config.port.livereload

    gulp.watch 'client/views/**/*', <[ client:html ]>
    gulp.watch <[ client/templates/**/* client/javascripts/**/* lib/javascripts/**/* ]>, <[ client:js ]>
    gulp.watch 'client/stylesheets/**/*', <[ client:css ]>
/*
 * Implementation details
 */
require! {
  path
}
require! {
  gulp
  'gulp-jade'
  'gulp-ruby-sass'
  'gulp-angular-templatecache'
  'gulp-uglify'
  'gulp-livescript'
  'gulp-concat'
  'gulp-livereload'
}
require! {
  'tiny-lr'
  'connect-livereload'
}
require! {
  '../config'
}

const livereload = tiny-lr!
/*
 * client tasks
 */
gulp.task 'client:html' ->
  return gulp.src 'client/views/**/*.jade'
  .pipe gulp-jade pretty: !config.env.is 'production'
  .pipe gulp.dest 'tmp/public'
  .pipe gulp-livereload(livereload)

gulp.task 'client:css' ->
  return gulp.src 'client/stylesheets/application.scss'
  .pipe gulp-ruby-sass do
    loadPath: [
      path.join ...<[ bower_components twbs-bootstrap-sass vendor assets stylesheets ]>
    ]
    cacheLocation: 'tmp/.sass-cache'
    style: if config.env.is 'production' then 'compressed' else 'nested'
  .pipe gulp.dest 'tmp/public'
  .pipe gulp-livereload(livereload)

gulp.task 'client:js:gcprettify' ->
  return gulp.src 'bower_components/google-code-prettify/src/prettify.js'
  .pipe gulp-uglify!
  .pipe gulp.dest 'tmp/.js-cache'

gulp.task 'client:templates' ->
  stream = gulp.src 'client/templates/**/*.jade'
  .pipe gulp-jade pretty: !config.env.is 'production'
  .pipe gulp-angular-templatecache do
    root: '/'
    module: 'npmgems.templates'
    standalone: true
  stream.=pipe gulp-uglify! if config.env.is 'production'
  return stream.pipe gulp.dest 'tmp/.js-cache'

gulp.task 'client:js:ls' ->
  stream = gulp.src 'client/javascripts/*.ls'
  .pipe gulp-livescript!
  .pipe gulp-concat 'application.js'
  stream.=pipe gulp-uglify! if config.env.is 'production'
  return stream.pipe gulp.dest 'tmp/.js-cache'

gulp.task 'client:js' <[ lib:js client:js:gcprettify client:templates client:js:ls ]> ->
  return gulp.src [
    'bower_components/angular/angular.min.js'
    'bower_components/angular-sanitize/angular-sanitize.min.js'
    'bower_components/angular-bootstrap/ui-bootstrap-tpls.min.js'
    'bower_components/firebase/firebase.js'
    'bower_components/firebase-simple-login/firebase-simple-login.js'
    'tmp/.js-cache/*.js'
  ]
  .pipe gulp-concat 'application.js'
  .pipe gulp.dest 'tmp/public'
  .pipe gulp-livereload(livereload)
# define!
exportedTasksDefinedBeginsHere!
