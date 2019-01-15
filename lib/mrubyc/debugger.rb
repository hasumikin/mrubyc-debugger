# frozen_string_literal: true

require "mrubyc/debugger/version"
require "mrubyc/debugger/config"
require "mrubyc/debugger/mrblib"
require "mrubyc/debugger/window"
require "thor"

module Mrubyc
  module Debugger
    class Error < StandardError; end
    # Your code goes here...
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
        pwd = Dir.pwd
        mrblibs = {
          models: [
            "#{pwd}/spec/fixtures/files/say.rb",
          ],
          tasks: [
            "#{pwd}/spec/fixtures/files/task_1.rb",
            "#{pwd}/spec/fixtures/files/task_2.rb",
          ]
        }
#        Mrubyc::Debugger::Mrblib.setup_models(mrblibs[:models])
        Mrubyc::Debugger::Window.start(mrblibs, options[:delay] || 0)
      end
    end
  end
end
