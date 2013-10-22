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
/*global module:false*/
module.exports = function(grunt) {
  /*jshint scripturl:true*/
  // Project configuration.
  grunt.initConfig({
    // Metadata.
    pkg: grunt.file.readJSON('package.json'),
    fdr: {
      src:    'src/',
      dest:   'dest/',
      lib:    'lib/',
      tmp:    'tmp/',
      vendor: 'vendor/'
    },
    banner: '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
      '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
      '<%= pkg.homepage ? "* " + pkg.homepage + "\\n" : "" %>' +
      '* Copyright (c) <%= grunt.template.today("yyyy") %> [<%= pkg.author.name %>](<%= pkg.author.url %>);\n' +
      ' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %> */\n',
    // Task configuration.
    'curl-dir': {
      scripts: {
        src: [
          // In order ...
          'https://ajax.googleapis.com/ajax/libs/angularjs/1.1.5/angular.js',
          'https://cdn.firebase.com/v0/firebase.js',
          'https://cdn.firebase.com/v0/firebase-simple-login.js',
          // no order ...
          'http://getbootstrap.com/2.3.2/assets/js/google-code-prettify/prettify.js',
          'http://www.google-analytics.com/analytics.js',
          'https://raw.github.com/angular-ui/bootstrap/gh-pages/ui-bootstrap-tpls-0.6.0.min.js'
        ],
        dest: '<%= fdr.vendor %>scripts/'
      }, styles: {
        src: [
          'http://getbootstrap.com/2.3.2/assets/js/google-code-prettify/prettify.css'
        ],
        dest: '<%= fdr.vendor %>styles/'
      }
    },
    concat: {
      components: {
        src: ['<%= fdr.lib %>header.ls', '<%= fdr.lib %>components/*.ls', '<%= fdr.lib %>footer.ls'],
        dest: '<%= fdr.lib %><%= pkg.name %>.ls'
      },
      ls: {
        src: ['<%= fdr.lib %><%= pkg.name %>.ls',  '<%= fdr.src %>index.ls', '<%= fdr.src %>**/*.ls'],
        dest: '<%= fdr.tmp %>.ls-cache/<%= pkg.name %>.ls',
        options: { process: indentToLet }
      },
      js: {
        src: [
          '<%= fdr.vendor %>scripts/angular.js',
          '<%= fdr.vendor %>scripts/firebase.js',
          '<%= fdr.vendor %>scripts/firebase-simple-login.js',
          '<%= fdr.vendor %>**/*.js',
          '<%= livescript.compile.dest %>'
        ],
        dest: '<%= fdr.dest %>script.js',
        options: { process: jsWrapper }
      },
      css: {
        src: ['<%= fdr.vendor %>**/*.css', '<%= sass.compile.dest %>'],
        dest: '<%= fdr.dest %>style.css'
      }
    },
    livescript: { compile: {
        src: '<%= concat.ls.dest %>',
        dest: '<%= concat.ls.dest %>.js'
      },          mixins: {
        expand: true,
        src: 'mixins/*.ls',
        dest: '<%= fdr.dest %>',
        cwd: '<%= fdr.src %>',
        ext: '.js',
        options: { bare: true }
      },          release: {
        src: '<%= fdr.lib %><%= pkg.name %>.ls',
        dest: 'release/<%= pkg.name %>.js'
      }
    },
    uglify: { release: {
        src: '<%= livescript.release.dest %>',
        dest: '<%= grunt.config.get("livescript.release.dest").replace(".js", ".min.js") %>'
      },
      options: { banner: '<%= banner %>' }
    },
    jade: { compile: {
        template: '<%= fdr.src %>index.jade.template',
        src: '<%= fdr.src %>index.jade',
        dest: '<%= fdr.dest %>index.html'
      },     mixins: {
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
        src: '<%= fdr.src %>index.scss',
        dest: '<%= fdr.tmp %>.sass-cache/<%= pkg.name %>.css',
        options: { cacheLocation: '<%= fdr.tmp %>.sass-cache' }
      }
    },
    cssmin: {
      compile: {
        src: '<%= concat.css.dest %>',
        dest: '<%= grunt.config.get("concat.css.dest").replace(".css", ".min.css") %>'
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
        files: ['<%= fdr.dest %>*'],
        options: { livereload: true }
      },
      js: {
        files: ['<%= fdr.src %>**/*.ls', '<%= fdr.lib %>**/*.ls', '<%= fdr.vendor %>**/*.js'],
        tasks: ['js:compile']
      },
      sass: {
        files: ['<%= fdr.src %>**/*.scss', '<%= fdr.vendor %>**/*.scss'],
        tasks: ['css:compile']
      },
      template: {
        files: ['<%= fdr.dest %>mixins/*.html', '<%= fdr.src %>*.jade.template'],
        tasks: ['template:jade']
      },
      jade: {
        files: ['<%= fdr.src %>*.jade'],
        tasks: ['jade:compile']
      },
      mixins: {
        files: ['<%= fdr.src %>mixins/*'],
        tasks: ['livescript:mixins', 'jade:mixins']
      },
      lib_test: {
        files: ['<%= jshint.lib_test.src %>'],
        tasks: ['jshint:lib_test', 'qunit']
      }
    },
    clean: {
      release: ['<%= fdr.tmp %>', '<%= fdr.dest %>']
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
  grunt.loadNpmTasks('grunt-curl');
  grunt.loadNpmTasks('grunt-livescript');
  grunt.loadNpmTasks('grunt-contrib-jade');
  grunt.loadNpmTasks('grunt-contrib-sass');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-connect');
  // 
  grunt.registerTask('ls:compile', ['concat:components', 'concat:ls', 'livescript:compile']);
  grunt.registerTask('js:compile', ['curl-dir:scripts', 'ls:compile', 'concat:js']);
  grunt.registerTask('css:compile', ['curl-dir:styles', 'sass:compile', 'concat:css', 'cssmin:compile']);
  grunt.registerTask('mixins:compile', ['livescript:mixins', 'jade:mixins']);
  grunt.registerTask('template:jade', function () {
    var file = grunt.file.read(grunt.config.get('jade.compile.template'));
    grunt.entityMap = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': '&quot;',
      "'": '&#39;',
      "/": '&#x2F;',
      "\n": "\\n"
    };
    file = grunt.template.process(file, {data: grunt});
    grunt.file.write(grunt.config.get('jade.compile.src'), file);
  });
  grunt.registerTask('default', ['clean:release', 'jshint', 'js:compile', 'css:compile', 'mixins:compile', 'template:jade', 'jade:compile']);
  grunt.registerTask('dev', ['default', 'connect', 'watch']);
  //
  grunt.registerTask('template:readme', function () {
    var readme = grunt.file.read('misc/README.md.template');
    readme = grunt.template.process(readme, {data: grunt});
    grunt.file.write('README.md', readme);
  });
  grunt.registerTask('release', ['default', 'concat:components', 'livescript:release', 'uglify:release', 'template:readme']);
};
