require 'uuid'
require 'connection'
require 'authentication'
require 'util'
require 'product_table'
require 'domains'
require 'dns'

# Example Usage:
# tda = GoDaddyReseller::API.new('apitest1', 'api1tda')
module GoDaddyReseller 
  class API
    include Authentication
    include Domains
    include DNS
    
    API_HOST = 'https://api.ote.wildwestdomains.com/wswwdapi/wapi.asmx'
    UID = UUID.new

    attr_accessor :connection
    
    def self.next_uid; @@last_uid = UID.generate end
    def self.last_uid; @@last_uid end
    
    # Setup the api with your source, version, and optionally a userid and password
    def initialize(userid = nil, pw = nil)
      self.connection = Connection.new
      connection.site = API_HOST
      credentials(userid, pw) if userid && pw
    end
    
    # shorthand for connection
    def c; return connection ;end
  end

end