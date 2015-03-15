gulp = require 'gulp'
gutil = require 'gulp-util'
source = require 'vinyl-source-stream'
browserify = require 'browserify'
coffeeReactify = require 'coffee-reactify'
envify = require 'envify/custom'
brfs = require 'brfs'
connect = require 'gulp-connect'
stylus = require 'gulp-stylus'
uglify = require 'gulp-uglify'
streamify = require 'gulp-streamify'
autoprefixer = require 'autoprefixer-stylus'
buildStatus = require 'build-status'
awspublish = require 'gulp-awspublish'


# amazon s3 deploy environment info

envs =
  staging:
    bucket: ''
    region: ''
  production:
    bucket: ''
    region: ''


# task to run a build status server and a connect server for static assets

statusServer = null

gulp.task 'static-server', ->

  statusServer = buildStatus.server()

  connect.server
    root: 'public'
    port: 3001


# run a peer signaling server (reloading source files)

ultrawaveServer = null

reloadServer = ->
  if server?
    ultrawaveServer.stop()
    delete require.cache[k] for k, v of require.cache

  try
    ultrawaveServer = new (require './server/ultrawave_server')
  catch e
    console.log "ERROR LOADING SERVER"
    console.log e


# build javascript assets

buildJS = (env) ->
  errorEmitted = false
  statusServer?.send 'building'

  browserify(
    entries: ['./scripts/index.coffee']
    extensions: ['.coffee', '.cjsx']
    debug: env != 'production'
  )
    .transform(coffeeReactify)
    .transform(envify NODE_ENV: env)
    .bundle()
    .on 'error', (e) ->
      errorEmitted = true
      statusServer?.send 'error'
      gutil.log "#{e}"
      @emit 'end'
    .on 'end', ->
      statusServer?.send 'done' unless errorEmitted
    .pipe source 'index.js'


# build CSS assets

buildCSS = (env) ->
  errorEmitted = false
  statusServer?.send 'building'

  gulp
    .src './styles/index.styl'
    .pipe(
      stylus(
        use: autoprefixer browsers: ['ios 7']
        compress: env is 'production'
        sourcemap:
          if env is 'production'
          then null
          else (
            inline: true
            sourceRoot: '.'
            basePath: 'styles'
          )
      )
    )
    .on 'error', (e) ->
      errorEmitted = true
      statusServer?.send 'error'
    .on 'end', ->
      statusServer?.send 'done' unless errorEmitted


# deploy to amazon s3

deploy = (env) ->

  console.log "deploying to #{env.bucket}"

  publisher = awspublish.create
    bucket: env.bucket
    region: env.region

  # define custom headers
  headers =
    'Cache-Control': 'max-age=315360000, no-transform, public'

  gulp.src('./public/**')

    # publisher will add Content-Length, Content-Type and headers specified above
    # If not specified it will set x-amz-acl to public-read by default
    .pipe publisher.publish headers

    # gzip, Set Content-Encoding headers and add .gz extension
    .pipe awspublish.gzip ext: ''

    # create a cache file to speed up consecutive uploads
    .pipe publisher.cache()

    # sync to delete old files from the bucket
    .pipe publisher.sync()

     # print upload updates to console
    .pipe awspublish.reporter()




gulp.task 'server', reloadServer

gulp.task 'watch-server', ['server'], ->
  gulp.watch ['./server/**'], ['server']

gulp.task 'dev-js', ->
  buildJS('development').pipe gulp.dest './public'

gulp.task 'prod-js', ->
  buildJS('production')
    .pipe streamify uglify()
    .pipe gulp.dest './public'

gulp.task 'watch-js', ['dev-js'], ->
  gulp.watch ['./scripts/**'], ['dev-js']

gulp.task 'dev-css', ->
  buildCSS('development').pipe gulp.dest './public'

gulp.task 'prod-css', ->
  buildCSS('production').pipe gulp.dest './public'

gulp.task 'watch-css', ['dev-css'], ->
  gulp.watch ['./styles/**'], ['dev-css']

gulp.task 'deploy-staging', ['prod-js', 'prod-css'], ->
  deploy envs.staging

gulp.task 'deploy-production', ['prod-js', 'prod-css'], ->
  deploy envs.production



gulp.task 'default', ['static-server', 'watch-server', 'watch-js', 'watch-css']



