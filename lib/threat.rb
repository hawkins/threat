require 'threat/version'
require 'httpclient'
require 'securerandom'

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
  alias :size :length

  def num_waiting
    @queue.num_waiting
  end
end

module Threat
  @@scheduler = Thread.new do
    loop do
      # TODO: How can we more effectively not waste too many cycles?
      sleep(0.1)

      unless @@inbox.empty?
        # TODO: Spawn agents to process the inbox
      end
    end
  end

  CLIENT = HTTPClient.new
  CLIENT.cookie_manager = nil

  @@inbox = Queue.new
  @@store = {}
  @@outbox = Queue.new

  def self.inbox
    ReadOnlyQueue.new @@inbox
  end
  def self.outbox
    ReadOnlyQueue.new @@outbox
  end

  def self.request(method, uri, args={})
    id = SecureRandom.uuid
    @@inbox.push(id: id, method: method, uri: uri, args: args)
    id
  end

  class Agent
    def initialize
      @client = CLIENT.clone
    end

    def invoke(request)
      res = @client.send(request[:method], request[:uri], request[:args])
      @@outbox.push(id: request[:id], res: res)
      res
    end
  end
end
