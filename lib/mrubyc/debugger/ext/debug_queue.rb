# frozen_string_literal: true

module DebugQueue
  refine Kernel do
    def puts(text)
      if $debug_queues
        $debug_queues[Thread.current[:index]] << {
          level: :debug,
          body: text
        }
      end
    end

    def sleep(sec)
      current_msec = Process.clock_gettime(Process::CLOCK_MONOTONIC_RAW, :millisecond)
      $sleep_queues[Thread.current[:index]] << (current_msec + (sec * 1000)) # wakeup at
      Thread.stop
    end
  end
end
