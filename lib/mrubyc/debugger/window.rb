# frozen_string_literal: true

require "mrubyc/debugger/ext/kernel"
require "mrubyc/debugger/ext/debug_queue"
require 'mrubyc/debugger/console.rb'
require "tempfile"

module Mrubyc
  module Debugger
    class Window
      class << self
        def start(mrblibs, delay)
          tasks = mrblibs[:tasks]
          $debug_queues = []
          $event_queues = []
          tasks.size.times do
            $debug_queues << Queue.new
            $event_queues << Queue.new
          end
          threads = []
          temp_tasks = []
          setup_models(mrblibs[:models])
          tasks.each_with_index do |task, index|
            tempfile = Tempfile.new
            temp_tasks << tempfile.path
            tempfile.puts "using DebugQueue"
            tempfile.puts File.read(task)
            tempfile.close
            threads << Thread.new(index) do
              Thread.current[:index] = index
              load temp_tasks[index]
            end
            $debug_queues[index] << {
              level: :info,
              body: "Task: #{File.basename(task)} started"
            }
          end
          threads << Thread.new do
            console = Mrubyc::Debugger::Console.new(temp_tasks)
            console.run
          end
          @@mutex = Mutex.new
          trace(temp_tasks, delay).enable do
            threads.each do|thr|
              thr.join
            end
          end
        end

        def trace(tasks, delay)
          TracePoint.new(:c_call, :call, :line) do |tp|
            number = nil
            caller_locations(1, 1).each do |caller_location|
              tasks.each_with_index do |task, index|
                number = index if caller_location.to_s.include?(File.basename(task))
              end
              if tp.method_id == :puts
                #sleep delay
              end
              if number
                @@mutex.lock
                message = {
                  method_id: tp.method_id,
                  lineno: tp.lineno,
                  caller_location: caller_location,
                  tp_binding: tp.binding
                }
                $event_queues[number].push message
                @@mutex.unlock
                sleep delay if tp.event == :line
              end
            end
          end
        end

        def setup_models(models)
          models.each do |model|
            load model
            class_name = File.basename(model, '.rb').split('_').map(&:capitalize).join
            Kernel.const_get(class_name).class_eval do
              def method_missing(method_name, *args)
                if $debug_queues
                  $debug_queues[Thread.current[:index]] << {
                    level: :error,
                    body: "method_missing: ##{method_name}"
                  }
                else
                  super
                end
              end
            end
          end
        end

      end
    end
  end
end
