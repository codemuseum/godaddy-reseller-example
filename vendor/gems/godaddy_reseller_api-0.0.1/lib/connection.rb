require 'cgi'
require 'net/https'
require 'date'
require 'time'
require 'uri'
require 'active_support'
require 'active_resource/formats'

module GoDaddyReseller 
  # This is a copy/trimmed version of ActiveResource::Connection, with added support for cookies
  class ConnectionError < StandardError
    attr_reader :response

    def initialize(response, message = nil)
      @response = response
      @message  = message
    end

    def to_s
      "Failed with #{response.code} #{response.message if response.respond_to?(:message)}"
    end
  end
  
  # This is a copy/trimmed version of ActiveResource::Connection
  class Connection
    HTTP_FORMAT_HEADER_NAMES = {  
      :get => 'Accept',
      :put => 'Content-Type',
      :post => 'Content-Type',
      :delete => 'Accept'
    }
    
    LOGIN_MIME_TYPE = 'application/x-www-form-urlencoded'
    XML_MIME_TYPE = 'application/xml'
    
    
    # All GoDaddy requests require the request to be wrapped in this XML
    def self.wrap_with_header_xml(xml)
      "<?xml version=\"1.0\"?>" + 
      "<wapi c1TRID=\"#{GoDaddyReseller::API.next_uid[0..50]}\">" +
         xml +
      "</wapi>"
    end
      
    def self.decode(xml)
      ActiveResource::Formats::XmlFormat.decode(xml)
    end
    
    # Encodes correctly for cookies, e.g. key1=value1; key2=value2
    def self.xml_encode_hash(hash)
      result = '';
      hash.keys.map(&:to_s).sort.each do |k|
        v = hash[k.to_sym]

        if v.is_a?(Array)
          result << v.map { |vh| xml_encode_hash({ k.to_sym => vh }) }.join
        elsif v.is_a?(Hash)
          result << "<#{k.to_s}"
          
          if v.key?(:_attributes) # save all the attributes
            v[:_attributes].keys.map(&:to_s).sort.each do |attrk|
              attrv = v[:_attributes][attrk.to_sym]
              result << " #{attrk.to_s}=\"#{attrv.to_s}\""
            end
            v.delete(:_attributes)
          end

          if v.empty?
            result << ' />'
          else
            result << '>' << xml_encode_hash(v) << "</#{k.to_s}>"
          end
        else
          result << "<#{k.to_s}>"
          result << "#{v.to_s}" 
          result << "</#{k.to_s}>"
        end 
      end
      result
    end
    
    # Encodes correctly for cookies, e.g. key1=value1; key2=value2
    def self.cookie_encode_hash(hash)
      pairs = Array.new
      hash.each_pair do |k,v|
        pairs << "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}" unless v.blank?
      end
      pairs.join('; ')
    end
    
    
    attr_reader :site, :timeout, :cookies
  
    # Execute a GET request.
    def get(path, headers = {})
      request(:get, path, build_request_headers(headers, :get))
    end

    # Execute a POST request.
    def post(path, body = '', headers = {})
      request(:post, path, (body.is_a?(Hash) ? self.class.wrap_with_header_xml(self.class.xml_encode_hash(body)) : body.to_s), build_request_headers(headers, :post))
    end
    
    # Set URI for remote service.
    def site=(site)
      @site = site.is_a?(URI) ? site : URI.parse(site)
    end
    
    # Set the number of seconds after which HTTP requests to the remote service should time out.
    def timeout=(timeout)
      @timeout = timeout
    end
    
    # Calls update on the cookies hash
    def update_cookies(hash)
      @cookies = {} unless @cookies
      @cookies.update(hash)
    end
    
    # Makes request to remote service.  # Be sure to handle Timeout::Error
    def request(method, path, *arguments)
      logger.info "#{method.to_s.upcase} #{site.scheme}://#{site.host}:#{site.port}#{site.path}#{path}" if logger
      result = nil
      ms = Benchmark.ms { result = http.send(method, "#{site.path}#{path}", *arguments) }
      logger.info "--> %d %s (%d %.0fms)" % [result.code, result.message, result.body ? result.body.length : 0, ms] if logger
      handle_response(result)
      # rescue Timeout::Error => e
      #   raise TimeoutError.new(e.message)
    end
    
    # Handles response and error codes from remote service.
    def handle_response(response)
      case response.code.to_i
        when 301,302
          raise(ConnectionError.new(response, "Redirection response code: #{response.code}"))
        when 200...400
          response
        else
          raise(ConnectionError.new(response, "Connection response code: #{response.code}"))
      end
    end
    
    # Creates new Net::HTTP instance for communication with remote service and resources.
    def http
      http             = Net::HTTP.new(@site.host, @site.port)
      http.use_ssl     = @site.is_a?(URI::HTTPS)
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl
      http.read_timeout = @timeout if @timeout # If timeout is not set, the default Net::HTTP timeout (60s) is used.
      http
    end
    
    
    # Builds headers for request to remote service.
    def build_request_headers(headers, http_method=nil)
      http_format_header(http_method).update(cookie_header).update(headers)
    end
    
    # Builds the cookie header according to what's stored in @cookies
    def cookie_header
      @cookies.nil? || @cookies.empty? ? {} : { 'Cookie' => self.class.cookie_encode_hash(@cookies) }
    end
    
    def http_format_header(http_method)
      {HTTP_FORMAT_HEADER_NAMES[http_method] => XML_MIME_TYPE}
    end
    
    def logger
      defined?(ActiveRecord) ? ActiveRecord::Base.logger : nil
    end
  end
end