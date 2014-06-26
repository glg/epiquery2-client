var gulp            = require('gulp');
var coffee          = require('gulp-coffee');
var util            = require('util');
var browserify      = require('gulp-browserify');
var rename          = require('gulp-rename');
var coffeelint      = require('gulp-coffeelint');

var src = './src/*.*';
var build = ['lint', 'transpile', 'browserify'];

gulp.task('default', build, function() {
    gulp.watch(src, build)
});

gulp.task('browserify', function() {
    gulp.src('./lib/browser-client.js')
        .pipe(browserify())
        .pipe(rename('epiclient_v2.js'))
        .pipe(gulp.dest('./lib/'))
});

gulp.task('transpile', ['browserify'], function() {
    gulp.src(src)
        .pipe(coffee({bare: true}).on('error', util.log))
        .pipe(gulp.dest('./lib/'))
});

gulp.task('lint', function() {
    gulp.src(src)
        .pipe(coffeelint('./etc/coffeelint.conf'))
        .pipe(coffeelint.reporter())
});