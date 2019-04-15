# frozen_string_literal: true

require "mrubyc/debugger/version"
require "mrubyc/debugger/config"
require "mrubyc/debugger/mrblib"
require "mrubyc/debugger/window"
require "thor"
require "yaml"
require "logger"

module Mrubyc
  module Debugger
    class Error < StandardError; end

    class Bootstrap < Thor
      default_command :start

      desc 'start', 'start debug window'
      option :delay, type: :numeric, default: 0.1,   banner: "Each of lines have a delay of this time (unit: second)"
      option :debug, type: :boolean, default: false, banner: "Log appears at /tmp/mrubyc-debugger.log"
      def start
        result = Mrubyc::Debugger::Config.check
        unless result
          puts "\e[31;1m"
          puts 'Error'
          result[:messages].each do |message|
            puts '  ' + message
          end
          puts "\e[0m"
          exit(1)
        end
        mrblib_dir = if File.exists?('.mrubycconfig')
          config = YAML.load_file('.mrubycconfig')
          config['mruby_lib_dir']
        else
          ENV['GEM_ENV'] == 'test' ? 'spec/fixtures/files' : 'mrblib'
        end
        models = Dir.glob(File.join(Dir.pwd, mrblib_dir, "models", "*.rb"))
        loops = Dir.glob(File.join(Dir.pwd, mrblib_dir, "loops", "*.rb"))
        if loops.size == 0
          puts "Exit as no loop found"
          exit(1)
        end
       mrblibs = {
          models: models,
          loops: loops
        }
#        Mrubyc::Debugger::Mrblib.setup_models(mrblibs[:models])
        yaml = File.join(Dir.pwd, "mrubyc-debugger.yml")
        stubs = if File.exists?(yaml)
          YAML.load_file(yaml)
        else
          {}
        end
        Mrubyc::Debugger::Window.setup_models(mrblibs[:models], stubs)
        $logger = Logger.new("/tmp/mrubyc-debugger.log")
        $logger.level = if options[:debug]
          Logger::DEBUG
        else
          Logger::INFO
        end
        Mrubyc::Debugger::Window.start(mrblibs, options[:delay])
      end
    end
  end
end
