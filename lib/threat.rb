require 'httpclient'
require 'securerandom'

require 'threat/version'
require 'threat/readonlyqueue'

module Threat
  def self.inbox
    ReadOnlyQueue.new @@inbox
  end

  def self.outbox
    ReadOnlyQueue.new @@outbox
  end

  def self.request(method, uri, args = {})
    id = SecureRandom.uuid
    @@inbox_a.push(id)
    @@inbox.push(id: id, method: method, uri: uri, args: args)
    id
  end
  # Programmatically define aliases for common HTTP methods
  %i[get put post patch delete head].each do |method|
    define_singleton_method(method) do |uri, args = {}|
      request method, uri, args
    end
  end

  ##
  # Configure the underlying HTTP client
  #
  # Note this also resets the library, discarding all requests, agents ...
  #
  # Accepts a block, used to expose the HTTPClient instance:
  #
  #   Thread::configure do |httpclient|
  #     # do whatever you want with the httpclient, for instance:
  #     httpclient.cookie_manager = nul
  #   end
  def self.configure
    yield CLIENT if block_given?

    @@inbox = Queue.new
    @@inbox_a = [] # TODO: Maybe replace inbox with an Array?
    @@outbox = Queue.new
    @@store = {}
    @@threads = {}

    start_scheduler
  end

  def self.join(id)
    # First see if we haven't scheduled the request yet
    while @@inbox_a.include? id
      sleep(0.001)
    end

    # Identify the thread and join it
    thread = @@threads[id]
    thread.value
  end

  private

  @@scheduler = nil

  CLIENT = HTTPClient.new

  def self.start_scheduler
    @@scheduler.kill unless @@scheduler.nil?

    @@scheduler = Thread.new do
      loop do
        # TODO: How can we more effectively not waste too many cycles?
        sleep(0.01)

        next if @@inbox.empty?

        # TODO: Check rate-limiting

        # Spawn an agent if safe to do so
        request = @@inbox.pop
        @@inbox_a.delete(request[:id])
        thr = Thread.new{
          a = Agent.new
          a.invoke request, @@outbox
        }
        @@threads[request[:id]] = thr
      end
    end
  end

  class Agent
    def initialize
      @client = CLIENT.clone
    end

    def invoke(request, outbox)
      res = @client.send(request[:method], request[:uri], request[:args])
      outbox.push(id: request[:id], res: res)
      res
    end
  end
end
