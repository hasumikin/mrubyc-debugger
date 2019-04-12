# frozen_string_literal: true

require "mrubyc/debugger/version"
require "mrubyc/debugger/config"
require "mrubyc/debugger/mrblib"
require "mrubyc/debugger/window"
require "thor"
require "yaml"

module Mrubyc
  module Debugger
    class Error < StandardError; end

    class Bootstrap < Thor
      default_command :start

      desc 'start', 'start debug window'
      option :delay, type: :numeric
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
        Mrubyc::Debugger::Window.setup_models(mrblibs[:models])
        Mrubyc::Debugger::Window.start(mrblibs, options[:delay] || 0)
      end
    end
  end
end
