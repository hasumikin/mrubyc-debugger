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
          config = YAML.file_load('.mrubycconfig')
          config['mrubyc_mrblib_dir']
        else
          ENV['GEM_ENV'] == 'test' ? 'spec/fixtures/files' : 'mrblib'
        end
        models = Dir.glob(File.join(Dir.pwd, mrblib_dir, "models", "*.rb"))
        tasks = Dir.glob(File.join(Dir.pwd, mrblib_dir, "tasks", "*.rb"))
        mrblibs = {
          models: models,
          tasks: tasks
        }
#        Mrubyc::Debugger::Mrblib.setup_models(mrblibs[:models])
        Mrubyc::Debugger::Window.start(mrblibs, options[:delay] || 0)
      end
    end
  end
end
