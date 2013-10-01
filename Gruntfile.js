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

var JADE_CWD_DIRPATH = 'src';

function renderFile () {
  var jade = require('jade');
  return function (filepath) {
    return jade.renderFile(JADE_CWD_DIRPATH+'/'+filepath, {pretty: true});
  };
}

/*global module:false*/
module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    // Metadata.
    pkg: grunt.file.readJSON('package.json'),
    banner: '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
      '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
      '<%= pkg.homepage ? "* " + pkg.homepage + "\\n" : "" %>' +
      '* Copyright (c) <%= grunt.template.today("yyyy") %> [<%= pkg.author.name %>](<%= pkg.author.url %>);\n' +
      ' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %> */\n',
    // Task configuration.
    concat: {
      livescript: {
        src: ['lib/<%= pkg.name %>.ls', 'src/**/*.ls'],
        dest: 'tmp/.ls-cache/<%= pkg.name %>.ls',
        options: { process: indentToLet }
      }
    },
    livescript: {
      dist: {
        src: '<%= concat.livescript.dest %>',
        dest: 'dist/script.js'
      },
      release: {
        src: 'lib/<%= pkg.name %>.ls',
        dest: 'release/<%= pkg.name %>.js'
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
    uglify: {
      options: {
        banner: '<%= banner %>'
      },
      dist: {
        src: '<%= livescript.dist.dest %>',
        dest: 'dist/script.js'
      },
      release: {
        src: '<%= livescript.release.dest %>',
        dest: 'release/<%= pkg.name %>.min.js'
      }
    },
    watch: {
      gruntfile: {
        files: '<%= jshint.gruntfile.src %>',
        tasks: ['jshint:gruntfile']
      },
      livereload: {
        options: { livereload: true },
        files: ['dist/**/*']
      },
      jsall: {
        files: ['src/**/*.ls', 'lib/**/*.ls'],
        tasks: ['jsall']
      },
      jade: {
        files: ['src/**/*.jade'],
        tasks: ['jade']
      },
      lib_test: {
        files: '<%= jshint.lib_test.src %>',
        tasks: ['jshint:lib_test', 'qunit']
      }
    },
    qunit: {
      files: ['test/**/*.html']
    },
    jade: {
      compile: {
        options: {
          pretty: true,
          data: {
            renderFile: renderFile(grunt)
          }
        },
        files: [
          {
            expand: true,
            src: '**/*.jade',
            dest: 'dist/',
            cwd: JADE_CWD_DIRPATH,
            ext: '.html'
          }
        ]
      }
    },
    connect: {
      server: {
        options: {
          port: 3333,
          base: 'dist'
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
  grunt.loadNpmTasks('grunt-contrib-connect');
  // Default task.
  grunt.registerTask('lsall', ['concat:livescript', 'livescript']);
  grunt.registerTask('jsall', ['lsall', 'jshint']);
  grunt.registerTask('dev', ['jsall', 'jade', 'connect', 'watch']);
  grunt.registerTask('default', ['jsall', 'uglify:dist', 'jade']);
  grunt.registerTask('build', [/*jshint scripturl:true*/'livescript:release', 'uglify:release']);
};
