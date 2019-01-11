require 'httpclient'
require 'securerandom'

require 'threat/version'

module Threat
  ##
  # Returns a frozen copy of the inbox as it was at this time
  #
  # Used for glimpsing into the state of Threat, but cannot
  # be used continuously
  def self.inbox
    @@inbox.dup.freeze
  end

  ##
  # Returns a frozen copy of the outbox as it was at this time
  #
  # Used for glimpsing into the state of Threat, but cannot
  # be used continuously
  def self.outbox
    outbox_without_threads = @@outbox.map do |item|
      item.reject { |k,v| k == :thread }
    end
    outbox_without_threads.freeze
  end

  ##
  # Queue a request to be scheduled later
  #
  # Arguments are provided to the underlying HTTPClient function
  # indicated by `:method` verbatim
  #
  #   Threat::request(:get, uri, header: headers, ...)
  #   # Under the hood:
  #   HTTPClient.get(uri, header: headers, ...)
  #
  # Returns the Threat ID for this request, which can be used
  # for tracking its response via #join
  def self.request(method, uri, args = {})
    id = SecureRandom.uuid
    @@inbox.push(id: id, method: method, uri: uri, args: args)
    puts "Requested: #{id}"
    @@scheduler.run
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

    @@inbox = []
    @@outbox = []
    @@threads = {}

    start_scheduler
  end

  ##
  # Join the thread running the given ID and await its response
  def self.join(id)
    # First see if we haven't scheduled the request yet
    # TODO: Race condition! Can we force the scheduler to schedule the ID?
    @@scheduler.run
    while @@inbox.include?(id)
      sleep(0.1)
    end

    # Identify the thread and join it
    #puts "Joining: #{id}"
    thread = @@threads[id]
    @@threads.delete(id)
    thread.value
  end

  private

  @@scheduler = nil

  CLIENT = HTTPClient.new

  def self.start_scheduler
    @@scheduler.kill unless @@scheduler.nil?

    @@scheduler = Thread.new do
      loop do
        Thread.stop if @@inbox.empty?

        # TODO: Check rate-limiting

        # Spawn an agent if safe to do so
        request = @@inbox.pop
        if request == nil
          # TODO: Race condition: @@inbox is empty but we're scheduling?
        else
          thr = Thread.new{
            a = Agent.new
            a.invoke(request, @@outbox)
          }
          @@threads[request[:id]] = thr
          #puts "Scheduled #{request[:id]}"
        end
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
