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
    @@inbox.push(id: id, method: method, uri: uri, args: args)
    id
  end
  # Programmatically define aliases for common HTTP methods
  %i[get post put head].each do |method|
    define_method("self.#{method}") do |uri, args = {}|
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
    @@store = {}
    @@outbox = Queue.new
    @@threads = []
  end

  private

  CLIENT = HTTPClient.new

  @@scheduler = Thread.new do
    loop do
      # TODO: How can we more effectively not waste too many cycles?
      sleep(0.1)

      next if @@inbox.empty?

      # TODO: Check rate-limiting

      # Spawn an agent if safe to do so
      @@threads << Thread.new do
        a = Agent.new
        request = @@inbox.pop
        a.invoke request, @@outbox
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
