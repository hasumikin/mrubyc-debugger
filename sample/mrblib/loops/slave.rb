while !$mutex
  relinquish()
end

while true
  sleep 1
  puts "trying to LOCK"
  $mutex.lock()
  $my_obj.still_not_defined_method
  sleep 2
  local_var = $my_obj.stub_method
  sleep 2
  puts "local_var: #{local_var}"
  $mutex.unlock()
  sleep 2
end

