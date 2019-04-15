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
          loops = mrblibs[:loops]
          $breakpoints = []
          $debug_queues = []
          $event_queues = []
          $sleep_queues = []
          loops.size.times do
            $debug_queues << Queue.new
            $event_queues << Queue.new
            $sleep_queues << Queue.new
          end
          $threads = []
          temp_loops = []
          setup_models(mrblibs[:models])
          loops.each_with_index do |loop, index|
            tempfile = Tempfile.new
            temp_loops << tempfile.path
            tempfile.puts "using DebugQueue; sleep 2"
            tempfile.puts File.read(loop)
            tempfile.close
            $threads << Thread.new(index) do
              Thread.current[:index] = index
              load temp_loops[index]
            end
            $debug_queues[index] << {
              level: :info,
              body: "loop: #{File.basename(loop)} started"
            }
          end
          $threads << Thread.new do
            console = Mrubyc::Debugger::Console.new(temp_loops)
            console.run
          end
          @@mutex = Mutex.new
          trace(temp_loops, delay).enable do
            $threads.each do|thr|
              thr.join
            end
          end
        end

        def trace(loops, delay)
          TracePoint.new(:c_call, :call, :line) do |tp|
            number = nil
            caller_locations(1, 1).each do |caller_location|
              loops.each_with_index do |loop, index|
                if caller_location.to_s.include?(File.basename(loop))
                  number = index
                  break
                end
              end
              if number
                @@mutex.lock
                event = {
                  method_id: tp.method_id,
                  lineno: tp.lineno,
                  caller_location: caller_location,
                  tp_binding: tp.binding
                }
                # breakpoint will be duplicated if method_id is not nil (== event is not :line)
                if tp.method_id.nil? && $breakpoints.any?{|bp| bp == [number, tp.lineno - 1]}
                  event[:breakpoint] = true
                end
                $event_queues[number].push event
                sleep delay if tp.event == :line
                # should stop after push event and sleep
                Thread.stop if event[:breakpoint] == true
                @@mutex.unlock
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
