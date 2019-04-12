while !$mutex
  relinquish()
end

b = 1

say = Say.new
while true
  puts "from task_2: " + b.to_s
  b += 1
  if b % 2 != 0
    $mutex.lock
    puts 'locked by job_2'
    sleep 1
    $mutex.unlock
  else
    say.hello
    say.not_implemented
    sleep 1
  end
  sleep 1
end

