module.exports = function (grunt) {

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    // Task configuration
    less: {
      css: {
        options: {
          compress: false,  //minifying the result
        },
        files: {
          "stylesheets/rbs.css": "stylesheets/less/core/rbs.less"
        }
      }
    },

    cssmin: {
      options: {
        banner: "/*! <%= pkg.name %> minified CSS file generated @ <%= grunt.template.today('dd-mm-yyyy') %> */\n"
      },
      css: {
        files: {
          "stylesheets/rbs.min.css": ["stylesheets/rbs.css"]
        }
      }
    },

    clean: {
      css: {
        src: ["stylesheets/rbs.css", "stylesheets/rbs.min.css"]
      },
      js: {
        src: ["javascripts/rbs.js", "javascripts/rbs.min.js"]
      }
    },

    concat: {
      options: {
        separator: ';',
      },
      frontend: {
        src: [
          // Bootstrap 5 & JQuery
          'bower_components/jquery/dist/jquery.js',
          'node_modules/bootstrap/dist/js/bootstrap.bundle.js',
          // Calendar & Moment
          'node_modules/moment/moment.js',
          'node_modules/@fullcalendar/core/index.global.js',
          'node_modules/@fullcalendar/daygrid/index.global.js',
          'node_modules/@fullcalendar/timegrid/index.global.js',
          'node_modules/@fullcalendar/interaction/index.global.js',
          // Legacy Bower Components
          'bower_components/eonasdan-bootstrap-datetimepicker/src/js/bootstrap-datetimepicker.js',
          'bower_components/bootstrapvalidator/dist/js/bootstrapValidator.js',
          'bower_components/minicolors/jquery.minicolors.js',
          'bower_components/jquery-ui/jquery-ui.js',
          'bower_components/gridmanager/src/gridmanager.js',
          'node_modules/bootbox/dist/bootbox.js',
          // Main.js is any custom JS
          'javascripts/main.js'
        ],
        dest: 'javascripts/rbs.js'
      }
    },



    jshint: {
      options: {
        curly: true,
        eqeqeq: true,
        eqnull: true,
        browser: true,
        globals: {
          jQuery: true
        },
      },
      all: ['Gruntfile.js', 'javascripts/main.js']
    },

    uglify: {
      frontend: {
        files: {
          'javascripts/rbs.min.js': ['javascripts/rbs.js']
        }
      }
    },

    imagemin: {
      png: {
        options: {
          optimizationLevel: 7
        },
        files: [
          {
            // Set to true to enable the following options…
            expand: true,
            // cwd is 'current working directory'
            cwd: '/images/',
            src: ['**/*.png'],
            // Could also match cwd line above. i.e. project-directory/img/
            dest: '/images/',
            ext: '.png'
          }
        ]
      },
      jpg: {
        options: {
          progressive: true
        },
        files: [
          {
            // Set to true to enable the following options…
            expand: true,
            // cwd is 'current working directory'
            cwd: '/images/',
            src: ['**/*.jpg'],
            // Could also match cwd. i.e. project-directory/img/
            dest: '/images/',
            ext: '.jpg'
          }
        ]
      }
    },

    watch: {
      js: {
        files: ['javascripts/main.js'],
        tasks: ['js']
      },
      css: {
        files: ['stylesheets/less/core/*.less', 'stylesheets/less/site/*.less'],
        tasks: ['css']
      }
    }


  });

  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-imagemin');
  grunt.loadNpmTasks('grunt-contrib-less');
  grunt.loadNpmTasks('grunt-injector');
  grunt.loadNpmTasks('grunt-rev');

  grunt.registerTask('css', ['clean:css', 'less:css', 'cssmin:css']);
  grunt.registerTask('js', ['jshint', 'clean:js', 'concat', 'uglify']);
  grunt.registerTask('img', ['imagemin']);
  grunt.registerTask('default', ['watch']);
};
