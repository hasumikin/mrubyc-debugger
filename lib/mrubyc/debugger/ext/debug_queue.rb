# frozen_string_literal: true

module DebugQueue
  refine Kernel do
    def puts(text)
      if Thread.current && $puts_queues
        $puts_queues[Thread.current[:index]] << {
          level: :debug,
          body: text }
      end
    end
  end
end
