require_relative 'request.rb'
require 'uri'
require 'net/http'
require 'json'
require 'active_support/core_ext/object/to_query'

class Kmb::GetStops < Kmb::Request
  def initialize(route, bound)
    super('getstops', route, bound)
  end

  def execute
    uri = URI::HTTP.build(host: ENDPOINT_HOST, path: ENDPOINT_PATH, query: query)
    req = Net::HTTP::Post.new(uri)
    set_default_header(req)

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      @response = JSON.parse(res.body)
    end
  end

  def basic_info
    execute unless @response
    @response['data']['basicInfo']
  end

  def route_stops
    execute unless @response
    @response['data']['routeStops']
  end

  def query
    {
      action: @action,
      route: @route,
      bound: @bound
    }.to_query
  end
end
