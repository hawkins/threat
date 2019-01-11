require 'httpclient'
require 'securerandom'

require 'threat/version'
require 'threat/readonlyqueue'

module Threat
  @@inbox = Queue.new
  @@store = {}
  @@outbox = Queue.new

  @@scheduler = Thread.new do
    loop do
      # TODO: How can we more effectively not waste too many cycles?
      sleep(0.1)

      unless @@inbox.empty?
        # TODO: Spawn agents to process the inbox
      end
    end
  end

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

  private

  CLIENT = HTTPClient.new
  CLIENT.cookie_manager = nil

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
