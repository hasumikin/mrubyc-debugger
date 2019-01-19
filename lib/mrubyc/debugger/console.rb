require 'curses'

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

  def initialize(tasks)
    @srcs = []
    tasks.each do |task|
      src = []
      File.open(task, 'r') do |f|
        f.each_line do |line|
          src << line
        end
      end
      @srcs << src
    end
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
        num.times do |i|
        wins[i][:src].resize(lines - 6, cols / num)
        wins[i][:out].resize(1, cols / num)
        wins[i][:var].resize(5, cols / num)
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
            tp = $event_queues[i].pop
            (1..(wins[i][:src].maxy - 2)).each do |y|
              wins[i][:src].setpos(y, 1)
              if !@srcs[i][y]
                wins[i][:src].addstr ' ' * wins[i][:src].maxx
              else
                lineno = tp[:lineno] - 1 # hide `using PutsQueue` line
                wins[i][:src].attron(A_REVERSE) if y == lineno
                wins[i][:src].attron(color_pair 16)
                wins[i][:src].attron(A_BOLD)
                wins[i][:src].addstr y.to_s.rjust(2).to_s
                wins[i][:src].attroff(A_BOLD)
                wins[i][:src].attroff(color_pair 16)
                wins[i][:src].addstr ' ' + @srcs[i][y]
                wins[i][:src].attroff(A_REVERSE) if y == lineno
              end
            end
            wins[i][:src].box(?|,?-,?+)
            wins[i][:src].refresh
            vars = {}
            tp[:tp_binding].local_variables.each do |var|
              vars[var] = tp[:tp_binding].local_variable_get(var).inspect
            end
            vars.each_with_index do |(k,v),j|
              wins[i][:var].setpos(j+1, 2)
              wins[i][:var].addstr (k.to_s + ' => ' + v).ljust(wins[i][:var].maxx)
            end
            wins[i][:var].attron(color_pair 16)
            wins[i][:var].box(?|,?-,?+)
            wins[i][:var].attroff(color_pair 16)
            wins[i][:var].refresh
          end
        end
        refresh
      end
    ensure
      close_screen
      system 'stty sane'
    end
  end

end

