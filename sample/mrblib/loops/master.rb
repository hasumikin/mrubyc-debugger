$my_obj = MyClass.new
local_var = 0

$mutex = Mutex.new

while true
  $mutex.lock()
  puts "LOCKED"
  sleep 3
  $mutex.unlock()
  if local_var > 100
    puts $my_obj.alert
    sleep 2
  end
  sleep 2
  local_var += 1
end

