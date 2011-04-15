require 'httparty'
require 'logger'
require 'elastic_searchable/active_record_extensions'

module ElasticSearchable
  DEFAULT_INDEX = 'elastic_searchable'
  include HTTParty
  format :json
  base_uri 'localhost:9200'

  class ElasticError < StandardError; end
  class << self
    attr_accessor :logger, :default_index, :offline

    # execute a block of work without reindexing objects
    def with_offline(&block)
      offline = true
      yield
    ensure
      offline = false
    end
    def offline?
      !!offline
    end
    # perform a request to the elasticsearch server
    # configuration:
    # ElasticSearchable.base_uri 'host:port' controls where to send request to
    # ElasticSearchable.debug_output outputs all http traffic to console
    def request(method, url, options = {})
      response = self.send(method, url, options)
      logger.debug "elasticsearch request: #{method} #{url} #{"took #{response['took']}ms" if response['took']}"
      validate_response response
      response
    end

    private
    # all elasticsearch rest calls return a json response when an error occurs.  ex:
    # {error: 'an error occurred' }
    def validate_response(response)
      error = response['error'] || "Error executing request: #{response.inspect}"
      raise ElasticSearchable::ElasticError.new(error) if response['error'] || ![Net::HTTPOK, Net::HTTPCreated].include?(response.response.class)
    end
  end
end

# configure default logger to standard out with info log level
ElasticSearchable.logger = Logger.new STDOUT
ElasticSearchable.logger.level = Logger::INFO

# configure default index to be elastic_searchable
# one index can hold many object 'types'
ElasticSearchable.default_index = ElasticSearchable::DEFAULT_INDEX

