gulp = require 'gulp'
colors = require 'colors'

# css
stylus = require 'gulp-stylus'
cmq = require 'gulp-combine-media-queries'
postcss = require 'gulp-postcss'
autoprefixer = require 'autoprefixer-core'
cssmin = require 'gulp-cssmin'
sourcemaps = require 'gulp-sourcemaps'
nib = require 'nib'

# utilities
notify = require 'gulp-notify'
plumber = require 'gulp-plumber'
gulpif = require 'gulp-if'
args = require('yargs').argv
sync = require 'browser-sync'
path = require 'path'
fs = require 'fs'

# js
uglify = require 'gulp-uglify'
browserify = require 'browserify'
source = require 'vinyl-source-stream'
streamify = require 'gulp-streamify'
watchify = require 'watchify'
production = args.p or args.production or no



paths =
	browserify: './src/app.coffee'
	js_output: 'app.js'
	stylus: './src/*.styl'
	deep_stylus: './src/**/*.styl'
	dest: './dest/'

gulp.task 'default', ['stylus', 'browserify']
gulp.task 'watch', ['browser-sync', 'watchjs'], ->
	gulp.watch paths.deep_stylus, ['stylus']



gulp.task 'stylus', ->
	gulp.src(paths.stylus)
		.pipe plumber errorHandler: notify.onError "Error: <%= error.message %>"
		.pipe gulpif not production, sourcemaps.init()
		.pipe stylus
			use: [nib()]
			'include css': true
			include: ['node_modules/']
			compress: production
			import: ['nib']
		.pipe gulpif production, cmq()
		.pipe postcss [ autoprefixer browsers: ['last 2 version', '> 1%'] ]
		.pipe gulpif production, cssmin()
		.pipe gulpif not production, sourcemaps.write()
		.pipe gulp.dest paths.dest
		.pipe sync.reload stream: true



gulp.task 'browser-sync', ->
	sync.init
		server:
			baseDir: paths.dest



buildScript = (files, watch) ->
	rebundle = (callback) ->
		stream = bundler.bundle()
		stream
			.on "error", notify.onError         # optional (for gulp-notify)
				title: "Compile Error"            #
				message: "<%= error.message %>"   #
			.pipe source paths.js_output
			.pipe gulpif production, streamify do uglify # optional (for gulp-uglify)
			.pipe gulp.dest paths.dest
			.pipe sync.reload stream: true      # optional (for browser-sync)

		stream.on 'end', ->
			do callback if typeof callback == "function"

	props = watchify.args
	props.entries = files
	props.debug = not production

	bundler = if watch then watchify(browserify props) else browserify props
	bundler.transform "coffee-reactify" # "coffeeify" or whatever or comment it
	bundler.on "update", ->
		now = new Date().toTimeString()[..7]
		console.log "[#{now.gray}] Starting #{"'browserify'".cyan}..."
		startTime = new Date().getTime()
		rebundle ->
			time = (new Date().getTime() - startTime) / 1000
			now = new Date().toTimeString()[..7]
			console.log "[#{now.gray}] Finished #{"'browserify'".cyan} after #{(time + 's').magenta}"

	rebundle()

gulp.task "browserify", ->                 # compile (slow)
	buildScript paths.browserify, false

gulp.task "watchjs", ->                    # watch and compile (first time slow, after fast)
	buildScript paths.browserify, true
