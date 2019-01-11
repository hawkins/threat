##
# A core ruby Queue with no ability to push or pop elements
#
# You can use any method to read status of the queue via this class.
#
# I.e.:
#
#   queue = Queue.new
#   queue << 1
#   queue << 2
#   q = ReadOnlyQueue.new queue
#   q.empty?   # false
#   q.size     # 2
#   queue.pop  # no method error
#   queue.push # no method error
class ReadOnlyQueue
  def initialize(queue)
    @queue = queue
  end

  def closed?
    @queue.closed?
  end

  def empty?
    @queue.empty?
  end

  def length
    @queue.length
  end
  alias size length

  def num_waiting
    @queue.num_waiting
  end
end
