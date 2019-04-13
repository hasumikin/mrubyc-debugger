# frozen_string_literal: true

require 'curses'

module Mrubyc
  module Debugger
    class Console

      include Curses

      COL_A = [
        COLOR_BLACK,
        COLOR_BLUE,
        COLOR_CYAN,
        COLOR_GREEN,
        COLOR_MAGENTA,
        COLOR_RED,
        COLOR_WHITE,
        COLOR_YELLOW
      ]

      ESCDELAY = 25

      def initialize(loops)
        @srcs = []
        loops.each do |loop|
          src = []
          File.open(loop, 'r') do |f|
            f.each_line do |line|
              src << line
            end
          end
          @srcs << src
        end
        cbreak # raw?
        noecho # stop echo back
        set_escdelay ESCDELAY # response speed. default 1000
        @cursor_pos = { x: 0, y: 1}
        @sleepers = Array.new(@srcs.size)
        @events = Array.new(@srcs.size)
      end

      def set_escdelay(ms)
        Curses.ESCDELAY = ms
      rescue NotImplementedError
      end

      def make_pair
        # 0 can't be changed
        no = 0
        COL_A.each do |c0|
          COL_A.each do |c1|
            init_pair(no, c0, c1)
            no += 1
          end
        end
      end

      def col_sample
        max = COL_A.size
        no = 0
        max.times do |y|
          max.times do |x|
            setpos(y, x * 6)
            s = " %03d "%no
            attron(color_pair(no))
            addstr(s)
            attroff(color_pair(no))
            no += 1
          end
        end
        s = "colors: %d"%(colors)
        setpos(12, 0)
        addstr(s)
        s = "color_pairs: %d"%(color_pairs)
        setpos(13, 0)
        addstr(s)
      end

      def show_colors
        col_sample
        refresh
        getch
      end

      def color_num_by(level)
        case level
        when :info
          24
        when :debug
          32
        when :warn
          56
        when :error
          40
        end
      end

      def run(show_colors_at_start = false)
        mainwin = init_screen
        mainwin.keypad true
        mainwin.timeout = 0
        curs_set(0)
        start_color
        make_pair
        show_colors if show_colors_at_start

        begin
          wins = []
          num = @srcs.size
          num.times do |i|
            win = {}
            win[:src] = mainwin.subwin(lines - 6, cols / num, 0, i * cols / num)
            win[:out] = mainwin.subwin(1, cols / num, lines - 6, i * cols / num)
            win[:var] = mainwin.subwin(5, cols / num, lines - 5, i * cols / num)
            wins << win
          end
          while true
            @key = mainwin.getch
            handle_key
            num.times do |i|
              wins[i][:src].resize(lines - 6, cols / num)
              wins[i][:out].resize(1, cols / num)
              wins[i][:var].resize(5, cols / num)
              unless $sleep_queues[i].empty?
                @sleepers[i] = $sleep_queues[i].pop
              end
              if @sleepers[i] && @sleepers[i] < Process.clock_gettime(Process::CLOCK_MONOTONIC_RAW, :millisecond)
                @sleepers[i] = nil
                $threads[i].run
              end
              unless $debug_queues[i].empty?
                message = $debug_queues[i].pop
                wins[i][:out].setpos(0, 0)
                color_num = color_num_by(message[:level])
                wins[i][:out].addstr '|'
                wins[i][:out].attron(color_pair color_num)
                wins[i][:out].addstr " #{message[:level].to_s[0].upcase}) " + message[:body].ljust(wins[i][:out].maxx-6)
                wins[i][:out].attroff(color_pair color_num)
                wins[i][:out].addstr '|'
                wins[i][:out].refresh
              end
              unless $event_queues[i].empty?
                @events[i] = $event_queues[i].pop
              end
              if @events[i]
                (1..(wins[i][:src].maxy - 2)).each do |y|
                  wins[i][:src].setpos(y, 1)
                  if !@srcs[i][y]
                    wins[i][:src].addstr ' ' * wins[i][:src].maxx
                  else
                    lineno = @events[i][:lineno] - 1 # hide `using DebugQueue` line
                    wins[i][:src].attron(A_UNDERLINE) if y == @cursor_pos[:y] && i == @cursor_pos[:x]
                    wins[i][:src].attron(A_REVERSE) if y == lineno
                    lineno_color = if $breakpoints.any? {|bp| bp == [i, y] }
                      21
                    else
                      16
                    end
                    wins[i][:src].attron(color_pair lineno_color)
                    wins[i][:src].attron(A_BOLD)
                    wins[i][:src].addstr y.to_s.rjust(2).to_s
                    wins[i][:src].attroff(A_BOLD)
                    wins[i][:src].attroff(color_pair lineno_color)
                    wins[i][:src].addstr ' ' + @srcs[i][y]
                    wins[i][:src].attroff(A_REVERSE) if y == lineno
                    wins[i][:src].attroff(A_UNDERLINE) if y == @cursor_pos[:y] && i == @cursor_pos[:x]
                  end
                end
                wins[i][:src].box(?|,?-,?+)
                wins[i][:src].refresh
                if @events[i][:breakpoint]
                  command_line(wins[i][:var], @events[i][:tp_binding])
                else
                  vars = {}
                  @events[i][:tp_binding].local_variables.each do |var|
                    vars[var] = @events[i][:tp_binding].local_variable_get(var).inspect
                  end
                  vars.each_with_index do |(k,v),j|
                    wins[i][:var].setpos(j+1, 2)
                    wins[i][:var].addstr (k.to_s + ' => ' + v).ljust(wins[i][:var].maxx)
                  end
                  box_var_win(wins[i][:var])
                end
              end
            end
            refresh
          end
        rescue => e
          sleep 5
        ensure
          finish
        end
      end

    private

      def clear_var_win(win)
        (1..3).each do |l|
          win.setpos(l, 1)
          win << " " * (win.maxx - 2)
        end
      end

      def box_var_win(win)
        win.attron(color_pair 16)
        win.box(?|,?-,?+)
        win.attroff(color_pair 16)
        win.refresh
      end

      def command_line(win, tp_binding)
        loop do
          clear_var_win(win)
          win.setpos(1, 1)
          win << " > "
          win.refresh
          str = getstr_with_echo(win)
          case str
          when "exit"
            clear_var_win(win)
            win.refresh
            resume
            return
          when ""
            # do nothing
          else
            win.setpos(2, 2)
            win << " => "
            index = str.index("=")
            args = if index
              [ str[0, index - 1].strip,
                str[index + 1, str.size - index].strip ]
            else
              str.strip
            end
            begin
              result = if args.is_a?(Array)
                tp_binding.local_variable_set(args[0], eval(args[1]))
              else
                if tp_binding.local_variables.map(&:to_s).include?(args)
                  tp_binding.local_variable_get(args)
                else
                  eval(args)
                end
              end
              win << result.to_s[0, win.maxx - 7]
            rescue => e
              win << e.to_s[0, win.maxx - 7]
            end
            win.setpos(3, 2)
            win << "Enter to continue"
            box_var_win(win)
            loop do
              case getch
              when nil
                sleep ESCDELAY / 1000.0
              when KEY_CTRL_J # Enter
                break
              end
            end
          end
        end
      end

      def getstr_with_echo(win)
        str = "".dup
        loop do
          case (c = Curses.getch)
          when nil
            # ignore
          when KEY_CTRL_J # Enter
            break if str.size > 0
          when String
            win << c
            win.refresh
            str << c
          when KEY_BACKSPACE
            if str.size > 0
              win.setpos(1, str.size + 3)
              win << " "
              win.setpos(1, str.size + 3)
              win.refresh
              str.chop!
            end
          end
        end
        str
      end

      def handle_key
        case @key
        when 27 # ESC
          exit(0)
        when "h"
          go_left
        when "j"
          go_down
        when "k"
          go_up
        when "l"
          go_right
        when " "
          breakpoint
        when "r"
          resume
        end
      end

      def resume
        2.times do # resume from $mutex line needs twice
          $threads.each do |thread|
            thread.run if thread.stop?
          end
        end
      end

      def breakpoint
        unless $breakpoints.delete([@cursor_pos[:x], @cursor_pos[:y]])
          $breakpoints << [@cursor_pos[:x], @cursor_pos[:y]]
        end
      end

      def go_left
        @cursor_pos[:x] -= 1
        if @cursor_pos[:x] < 0
          @cursor_pos[:x] = @srcs.size - 1
        end
        rescue_overflow
      end

      def go_right
        @cursor_pos[:x] += 1
        if @cursor_pos[:x] >= @srcs.size
          @cursor_pos[:x] = 0
        end
        rescue_overflow
      end

      def rescue_overflow
        if @cursor_pos[:y] >= @srcs[@cursor_pos[:x]].size
          @cursor_pos[:y] = @srcs[@cursor_pos[:x]].size - 1
        end
      end

      def go_down
        @cursor_pos[:y] += 1
        if @cursor_pos[:y] >= @srcs[@cursor_pos[:x]].size
          @cursor_pos[:y] = 1
        end
      end

      def go_up
        @cursor_pos[:y] -= 1
        if @cursor_pos[:y] == 0
          @cursor_pos[:y] = @srcs[@cursor_pos[:x]].size - 1
        end
      end

      def finish
        close_screen
        system "stty sane"
        puts "finished"
      end

    end
  end
end
