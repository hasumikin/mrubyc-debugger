require 'curses'

include Curses
$col_a = [
  COLOR_BLACK,
  COLOR_BLUE,
  COLOR_CYAN,
  COLOR_GREEN,
  COLOR_MAGENTA,
  COLOR_RED,
  COLOR_WHITE,
  COLOR_YELLOW ]
# 背景色・文字色の組み合わせを作成
def make_pair
# 0は実際には変更不可
no = 0
$col_a.each { |c0|
  $col_a.each { |c1|
    init_pair(no,c0,c1)
    no += 1
  }
}
end
def col_sample()
  cu = Curses
  max = $col_a.size
  # それぞれ表示
  no = 0
  max.times { |y|
    max.times { |x|
      cu.setpos(y,x*6)
      s = " %03d "%no
      cu.attron(cu.color_pair(no))
      cu.addstr(s)
      cu.attroff(cu.color_pair(no))
      no += 1
    }
  }
  # 色関係の情報を表示
  s = "colors: %d"%(cu.colors)
  cu.setpos(12,0)
  cu.addstr(s)
  s = "color_pairs: %d"%(cu.color_pairs)
  cu.setpos(13,0)
  cu.addstr(s)
end
mainwin = init_screen
curs_set(0)
start_color
make_pair
col_sample
refresh
getch
srcs = [nil]
[1, 2].each do |i|
  src = []
  File.open("#{Dir.pwd}/spec/fixtures/files/task_#{i}.rb", 'r') do |f|
    f.each_line do |line|
      src << line
    end
  end
  srcs << src
end
begin
  wins = [nil]
  num = 2
  num.times do |i|
    win = {}
    win[:src] = mainwin.subwin(lines-6, cols/num, 0, i*cols/num)
    win[:out] = mainwin.subwin(1, cols/num, lines-6, i*cols/num)
    win[:var] = mainwin.subwin(5, cols/num, lines-5, i*cols/num)
    wins << win
  end
  while true
    [1, 2].each do |i|
    wins[i][:src].resize(lines-6, cols/num)
    wins[i][:out].resize(1, cols/num)
    wins[i][:var].resize(5, cols/num)
      unless $debug_queues[i].empty?
        message = $debug_queues[i].pop
        wins[i][:out].setpos(0, 0)
        color = nil
        level = 'I'
        case message[:level]
        when :info
          color = 24
          level = 'I'
        when :debug
          color = 32
          level = 'D'
        when :warn
          color = 56
          level = 'W'
        when :error
          color = 40
          level = 'E'
        end
        wins[i][:out].addstr '|'
        wins[i][:out].attron(color_pair color)
        wins[i][:out].addstr " #{level}) " + message[:body].ljust(wins[i][:out].maxx-6)
        wins[i][:out].attroff(color_pair color)
        wins[i][:out].addstr '|'
        wins[i][:out].refresh
      end
      unless $event_queues[i].empty?
        tp = $event_queues[i].pop
        (1..(wins[i][:src].maxy-2)).each do |y|
          wins[i][:src].setpos(y, 1)
          if !srcs[i][y]
            wins[i][:src].addstr ' ' * wins[i][:src].maxx
          else
            lineno = tp[:lineno] - 1 # hide `using PutsQueue` line
            wins[i][:src].attron(A_REVERSE) if y == lineno
            wins[i][:src].attron(color_pair 16)
            wins[i][:src].attron(A_BOLD)
            wins[i][:src].addstr y.to_s.rjust(2).to_s
            wins[i][:src].attroff(A_BOLD)
            wins[i][:src].attroff(color_pair 16)
            wins[i][:src].addstr ' ' + srcs[i][y]
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
