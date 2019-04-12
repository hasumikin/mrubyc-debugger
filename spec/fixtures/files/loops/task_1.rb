sleep 1
$mutex = Mutex.new

a = 1
while true
  $mutex.lock
  puts "from task_1: " + a.to_s
  $mutex.unlock
  a += 1
  sleep 10
end

