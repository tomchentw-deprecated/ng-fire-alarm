!function exportedTasksDefinedBeginsHere
  gulp.task 'client' <[ client:html client:css client:js ]> !(done) ->
    if config.env.is 'production'
      gulp.start 'client:html' done
    else
      livereload.listen config.port.livereload, done

      gulp.watch 'client/views/**/*', <[ client:html ]>
      gulp.watch <[ client/templates/**/* client/javascripts/**/* lib/javascripts/**/* ]>, <[ client:html client:js ]>
      gulp.watch 'client/stylesheets/**/*', <[ client:css ]>
/*
 * Implementation details
 */
require! {
  fs
  path
}
require! {
  gulp
  'gulp-jade'
  'gulp-ruby-sass'
  'gulp-minify-css'
  'gulp-angular-templatecache'
  'gulp-uglify'
  'gulp-livescript'
  'gulp-concat'
  'gulp-livereload'
  'gulp-rev'
}
require! {
  hljs: 'highlight.js'
  'tiny-lr'
  'connect-livereload'
}
require! {
  '../lib/gulpfile'
  '../config'
}

const livereload = tiny-lr!

function identity
  it

function valueOf
  @[it]

function prependTimestampFactory (filepath)
  if config.env.is 'production' and fs.existsSync filepath
    fs.readFileSync filepath, 'utf8'
    |> JSON.parse
    |> valueOf.bind
  else
    identity
/*
 * client tasks
 */
gulp.task 'client:html:partials' ->
  return gulp.src 'client/views/partials/*.jade'
  .pipe gulp-jade pretty: true
  .pipe gulp.dest 'tmp/.html-cache/partials'

gulp.task 'client:js:partials' ->
  return gulp.src 'client/javascripts/partials/*.ls'
  .pipe gulp-livescript bare: true
  .pipe gulp.dest 'tmp/.js-cache/partials'

gulp.task 'client:html' <[ client:html:partials client:js:partials ]> ->
  return gulp.src 'client/views/*.jade'
  .pipe gulp-jade do
    pretty: !config.env.is 'production'
    locals:
      highlight: ->
        hljs.highlight do
          path.extname it .substr 1
          fs.readFileSync it, 'utf8'
        .value
      javascriptIncludeTag: prependTimestampFactory './tmp/js-manifest/rev-manifest.json'
      stylesheetLinkTag: prependTimestampFactory './tmp/css-manifest/rev-manifest.json'

  .pipe gulp.dest 'tmp/public'
  .pipe gulp-livereload(livereload)

gulp.task 'client:css:scss' ->
  return gulp.src 'client/stylesheets/application.scss'
  .pipe gulp-ruby-sass do
    loadPath: [
      path.join ...<[ bower_components twbs-bootstrap-sass vendor assets stylesheets ]>
    ]
    cacheLocation: 'tmp/.sass-cache'
    style: if config.env.is 'production' then 'compressed' else 'nested'
  .pipe gulp.dest 'tmp/.css-cache'

gulp.task 'client:css:bower_components' ->
  stream = gulp.src <[
    bower_components/angular/angular-csp.css
  ]>
  stream.=pipe gulp-minify-css! if config.env.is 'production'
  return stream.pipe gulp.dest 'tmp/.css-cache'

gulp.task 'client:css' <[ client:css:scss client:css:bower_components ]> ->
  stream = gulp.src 'tmp/.css-cache/*.css'
  .pipe gulp-concat 'application.css'
  stream.=pipe gulp-rev! if config.env.is 'production'
  stream.=pipe gulp.dest 'tmp/public'
  .pipe gulp-livereload(livereload)
  if config.env.is 'production'
    stream.=pipe gulp-rev.manifest!
    .pipe gulp.dest 'tmp/css-manifest'
  return stream

gulp.task 'client:templates' ->
  stream = gulp.src 'client/templates/**/*.jade'
  .pipe gulp-jade pretty: !config.env.is 'production'
  .pipe gulp-angular-templatecache do
    root: '/'
    module: 'tc-spa-boilerplate.templates'
    standalone: true
  stream.=pipe gulp-uglify! if config.env.is 'production'
  return stream.pipe gulp.dest 'tmp/.js-cache'

gulp.task 'client:js:ls' ->
  stream = gulp.src <[
    client/javascripts/application.ls
    client/javascripts/**/*.ls
  ]>
  .pipe gulp-concat 'application.js'
  .pipe gulp-livescript!
  stream.=pipe gulp-uglify! if config.env.is 'production'
  return stream.pipe gulp.dest 'tmp/.js-cache'

gulp.task 'client:js:bower_components' ->
  # stream = gulp.src [
  # ]
  # stream.=pipe gulp-uglify! if config.env.is 'production'
  # return stream.pipe gulp.dest 'tmp/.js-cache'

gulp.task 'client:js' <[ lib:js client:templates client:js:ls client:js:bower_components ]> ->
  stream = gulp.src [
    'bower_components/angular/angular.min.js'
    'bower_components/angular-sanitize/angular-sanitize.min.js'
    'bower_components/angular-bootstrap/ui-bootstrap-tpls.min.js'
    'bower_components/firebase/firebase.js'
    'bower_components/firebase-simple-login/firebase-simple-login.js'
    'tmp/.js-cache/*.js'
  ]
  .pipe gulp-concat 'application.js'
  stream.=pipe gulp-rev! if config.env.is 'production'
  stream.=pipe gulp.dest 'tmp/public'
  .pipe gulp-livereload(livereload)
  if config.env.is 'production'
    stream.=pipe gulp-rev.manifest!
    .pipe gulp.dest 'tmp/js-manifest'
  return stream
# define!
exportedTasksDefinedBeginsHere!
