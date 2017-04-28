require_relative 'request.rb'
require 'uri'
require 'net/http'
require 'json'
require 'active_support/core_ext/object/to_query'

class Kmb::GetETA < Kmb::Request
  def initialize(route, bound, bsiCode, lang='1', serviceType='1', seq='1')
    super('get_ETA', route, bound)
    @lang = lang
    @serviceType = serviceType
    @bsiCode = bsiCode
    @seq = seq
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

  def eta
    execute unless @response
    @response['data']['response']
  end

  def query
    {
      action: @action,
      route: @route,
      bound: @bound,
      lang: @lang,
      servicetype: @serviceType,
      bsiCode: @bsiCode,
      seq: @seq
    }.to_query
  end
end
