/*
 * When concating ls files, we need a wrapper and we use `let` keyword to do this.
 * So, indentions of each lines are required!!
 */
function indentToLet (src) {
  return src.split('\n').reduce(function (array, line) {
    array.push('  ', line, '\n'); 
    return array;
  }, ['let\n']).join('');
}

function jsWrapper (src) {
  if (src.match(/^\(function\(\)\{/)) { return src; }
  return "(function () {\n" + src + "\n}).call(this);";
}

function renderMixin (grunt) {
  var path = require('path');
  return function (filepath) {
    // throw new Error(grunt, path, filepath);
    var segments  = filepath.split('.'),
        lastSeg   = segments.pop(),
        taskname  = null;
    if (lastSeg === 'ls') {
      taskname  = 'livescript';
    } else {
      taskname  = lastSeg;
    }
    segments.unshift("./", grunt.config.get(taskname+".mixin.dest"));
    segments.push(segments.pop() + grunt.config.get(taskname+".mixin.ext"));
    filepath = path.join.apply(path, segments);
    return grunt.file.read(filepath);
  };
}

/*global module:false*/
module.exports = function(grunt) {
  
  // Project configuration.
  grunt.initConfig({
    // Metadata.
    pkg: grunt.file.readJSON('package.json'),
    fdr: {
      src:    'src',
      dest:   'dest',
      lib:    'lib',
      vendor: 'vendor'
    },
    banner: '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
      '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
      '<%= pkg.homepage ? "* " + pkg.homepage + "\\n" : "" %>' +
      '* Copyright (c) <%= grunt.template.today("yyyy") %> [<%= pkg.author.name %>](<%= pkg.author.url %>);\n' +
      ' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %> */\n',
    // Task configuration.
    concat: { 
      ls: {
        src: ['<%= fdr.lib %>/**/*.ls', '<%= fdr.src %>/**/*.ls'],
        dest: 'tmp/.ls-cache/<%= pkg.name %>.ls',
        options: { process: indentToLet }
      },
      js: {
        src: [
          '<%= fdr.vendor %>/scripts/angular.js',
          '<%= fdr.vendor %>/scripts/firebase.js', '<%= fdr.vendor %>/scripts/firebase-simple-login.js',
          '<%= fdr.vendor %>/**/*.js',
          '<%= livescript.compile.dest %>'
        ],
        dest: '<%= fdr.dest %>/script.js',
        options: { process: jsWrapper }
      },
      css: {
        src: ['<%= fdr.vendor %>/**/*.css', 'tmp/.sass-cache/<%= pkg.name %>.css'],
        dest: '<%= fdr.dest %>/style.css'
      }
    },
    livescript: { compile: {
        src: '<%= concat.ls.dest %>',
        dest: '<%= concat.ls.dest %>.js'
      },          mixin: {
        expand: true,
        src: 'mixins/*.ls',
        dest: '<%= fdr.dest %>',
        cwd: '<%= fdr.src %>',
        ext: '.js',
        options: { bare: true }
      },          release: {
        src: 'lib/<%= pkg.name %>.ls',
        dest: 'release/<%= pkg.name %>.js'
      }
    },
    uglify: { compile: {
        src: '<%= concat.js.dest %>',
        dest: '<%= concat.js.dest.replace(".js", ".min.js") %>'
      },      release: {
        src: '<%= livescript.release.dest %>',
        dest: '<%= livescript.release.dest.replace(".js", ".min.js") %>'
      },
      options: { banner: '<%= banner %>' }
    },
    jade: { compile: {
        src: '<%= fdr.src %>/index.jade',
        dest: '<%= fdr.dest %>/index.html',
        ext: '.html',
        options: {
          data: { renderMixin: renderMixin(grunt) }
        }
      },     mixin: {
        expand: true,
        cwd: '<%= fdr.src %>',
        src: 'mixins/*.jade',
        dest: '<%= fdr.dest %>',
        ext: '.html'
      }, options: { 
        pretty: true
      }
    },
    sass: { compile: {
        src: '<%= fdr.src %>/index.scss',
        dest: 'tmp/.sass-cache/<%= pkg.name %>.css',
        options: { cacheLocation: 'tmp/.sass-cache' }
      }
    },
    cssmin: {
      compile: {
        src: '<%= concat.css.dest %>',
        dest: '<%= concat.css.dest.replace(".css", ".min.css") %>'
      }
    },
    jshint: {
      options: {
        curly: true,
        eqeqeq: true,
        immed: true,
        latedef: true,
        newcap: true,
        noarg: true,
        sub: true,
        undef: true,
        unused: true,
        boss: true,
        eqnull: true,
        browser: true,
        globals: {
          angular: true,
          require: true
        }
      },
      gruntfile: {
        src: 'Gruntfile.js'
      },
      lib_test: {
        src: ['lib/**/*.js', 'test/**/*.js']
      }
    },
    watch: {
      gruntfile: {
        files: ['<%= jshint.gruntfile.src %>'],
        tasks: ['jshint:gruntfile']
      },
      livereload: {
        files: ['<%= fdr.dest %>/**/*'],
        options: { livereload: true }
      },
      js: {
        files: ['<%= fdr.src %>/**/*.ls', '<%= fdr.lib %>/**/*.js', '<%= fdr.vendor %>/**/*.js'],
        tasks: ['js:compile', /*jshint scripturl:true*/'livescript:mixin']
      },
      sass: {
        files: ['<%= fdr.src %>/**/*.scss', '<%= fdr.vendor %>/**/*.scss'],
        tasks: ['css:compile']
      },
      jade: {
        files: ['<%= fdr.src %>/**/*.jade'],
        tasks: ['jade:mixin', 'jade:compile']
      },
      lib_test: {
        files: ['<%= jshint.lib_test.src %>'],
        tasks: ['jshint:lib_test', 'qunit']
      }
    },
    qunit: { files: ['test/**/*.html'] },
    connect: {
      server: {
        options: {
          port: 3333,
          base: '<%= fdr.dest %>'
        }
      }
    }
  });

  // These plugins provide necessary tasks.
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  // grunt.loadNpmTasks('grunt-contrib-qunit');
  //
  grunt.loadNpmTasks('grunt-livescript');
  grunt.loadNpmTasks('grunt-contrib-jade');
  grunt.loadNpmTasks('grunt-contrib-sass');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-connect');
  // Default task.
  grunt.registerTask('ls:compile', ['concat:ls', /*jshint scripturl:true*/'livescript:compile']);
  grunt.registerTask('js:compile', ['ls:compile', 'concat:js', 'uglify:compile']);
  grunt.registerTask('css:compile', ['sass:compile', 'concat:css', 'cssmin:compile']);
  grunt.registerTask('mixin:compile', [/*jshint scripturl:true*/'livescript:mixin', 'jade:mixin']);
  grunt.registerTask('default', ['jshint', 'js:compile', 'css:compile', 'mixin:compile', 'jade:compile']);
  grunt.registerTask('dev', ['default', 'connect', 'watch']);
  grunt.registerTask('build', [/*jshint scripturl:true*/'livescript:release', 'uglify:release']);
};
