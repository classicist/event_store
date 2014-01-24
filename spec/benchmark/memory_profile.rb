lib = File.expand_path('../../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'event_store'

EventStore.connect :adapter => :postgres, :database => 'event_store_performance', :host => 'localhost'

iterations = 100
loads_per_iteration = 100

# GC.stat output explanation
# COUNT: the number of times a GC ran (both full GC and lazy sweep are
# included)
# HEAP_USED: the number of heaps that have more than 0 slots used in them. The
# larger this number, the slower your GC will be.
# HEAP_LENGTH: the total number of heaps allocated in memory. For example 1648
# means - about 25.75MB is allocated to Ruby heaps. (1648 * (2 << 13)).to_f /
# (2 << 19)
# HEAP_INCREMENT: Is the number of extra heaps to be allocated, next time Ruby
# grows the number of heaps (as it does after it runs a GC and discovers it
# does not have enough free space), this number is updated each GC run to be
# 1.8 * heap_used. In later versions of Ruby this multiplier is configurable.
# HEAP_LIVE_NUM: This is the running number objects in Ruby heaps, it will
# change every time you call GC.stat
# HEAP_FREE_NUM: This is a slightly confusing number, it changes after a GC
# runs, it will let you know how many objects were left in the heaps after the
# GC finished running. So, in this example we had 102447 slots empty after the
# last GC. (it also increased when objects are recycled internally - which can
# happen between GCs)
# HEAP_FINAL_NUM: Is the count of objects that were not finalized during the
# last GC
# TOTAL_ALLOCATED_OBJECT: The running total of allocated objects from the
# beginning of the process. This number will change every time you allocate
# objects. Note: in a corner case this value may overflow.
# TOTAL_FREED_OBJECT: The number of objects that were freed by the GC from the
# beginning of the process.

def output_gc_data
  puts GC.stat
end

iterations.times do
  loads_per_iteration.times do
    client = EventStore::Client.new(rand(300)+1, :device)
    client.snapshot
  end
  output_gc_data
end
