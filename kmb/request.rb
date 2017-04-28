module Kmb
  class Request
    ENDPOINT_HOST = 'search.kmb.hk'
    ENDPOINT_PATH = '/KMBWebSite/Function/FunctionRequest.ashx'
    attr_accessor :action
    attr_accessor :route
    attr_accessor :bound
    attr_accessor :response

    def initialize(action, route, bound)
      @action = action
      @route = route.upcase
      @bound = bound
    end

    def set_default_header(req)
      req['Origin'] = 'http://search.kmb.hk'
      req['Accept-Encoding'] = 'gzip, deflate'
      req['Accept-Language'] = 'en-US'
      req['Content-Type'] = 'application/json; charset=utf-8'
      req['Accept'] = 'application/json, text/javascript, */*'
      req['Referer'] = 'http://search.kmb.hk/KMBWebSite/'
      req['X-Requested-With'] = 'XMLHttpRequest'
      req
    end

    def execute
      raise NotImplementedError
    end
  end
end
