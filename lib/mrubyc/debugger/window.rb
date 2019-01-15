# frozen_string_literal: true

require "mrubyc/debugger/ext/kernel"
require "mrubyc/debugger/ext/debug_queue"

module Mrubyc
  module Debugger
    class Window
      class << self
        def start(mrblibs, delay)
          tasks = mrblibs[:tasks]
          tasks.unshift('mrubyc/debugger/task/console.rb')
          $debug_queues = []
          $event_queues = []
          tasks.size.times do
            $debug_queues << Queue.new
            $event_queues << Queue.new
          end
          threads = []
          setup_models(mrblibs[:models])
          tasks.each_with_index do |task, index|
            threads << Thread.new(index) do
              Thread.current[:index] = index
              load task
            end
            $debug_queues[index] << {
              level: :info,
              body: "Task: #{File.basename(task)} started"
            }
          end
          @@mutex = Mutex.new
          trace(tasks, delay).enable do
            threads.each do|thr|
            #  puts thr
              thr.join
            end
          end
        end

        def trace(tasks, delay)
          TracePoint.new(:c_call, :call, :line) do |tp|
            number = nil
            caller_locations(1, 1).each do |caller_location|
              tasks.each_with_index do |task, index|
                next if index == 0
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
          trace = TracePoint.new(:class) do |tp|
            if tp.defined_class != nil
            #tp.defined_class.class_evel do
            Say.class_evel do
              def method_missing
                if Thread.current && $debug_queues
                  $debug_queues[Thread.current[:index]] << {
                    level: :warn,
                    body: "method_missing: ##{method_name}"
                  }
                else
                  super
                end
              end
            end
            end
          end
          trace.enable do
            models.each do |model|
              require model
            end
          end
        end

      end
    end
  end
end
