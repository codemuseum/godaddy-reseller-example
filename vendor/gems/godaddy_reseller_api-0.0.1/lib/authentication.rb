module GoDaddyReseller 
  # Example Usage:
  # gdr.authenticate # authenticates on the server
  # gdr.account # returns the connection detials
  module Authentication
    def self.included(base) # :nodoc:
      base.class_eval do
        attr_accessor :user_id, :password, :logged_in, :account, :timeout_at, :expires_at
      end
    end
    
    def credentials(userid, pw)
      self.user_id = userid
      self.password = pw
    end
    
    def creds
      c.class.credentials_hash(user_id, password)
    end
    
    def describe
      response = c.soap(:Describe, 
        { :Describe => 
          { :_attributes => 
            { :xmlns => 'http://wildwestdomains.com/webservices/' }}.update(creds).update(c.class.uuid_hash) }
      )
      result = c.class.decode_soap(response.body)
      if result['result']['code'] == '1000'
        self.timeout_at = Time.now + result['resdata']['timeout'].to_i
        true
      else
        clear_login_data
      end
    end
    alias_method :authenticate, :describe
    
    
    
    # Explicitely log in.  Usually called automatically within this library.  Returns true or false.
    # def authenticate
    #   response = c.post("/login", { :login => { :attr_msgDelimiter => '', :id => user_id, :pwd => password }})
    #   
    #   result = c.class.decode(response.body)
    #   if result['result']['code'] == '1000'
    #     self.account = result['resdata']
    #     self.timeout_at = Time.now + result['resdata']['timeout'].to_i
    #     self.expires_at = Time.now + 24.hours
    #     # c.update_cookies({'JSESSIONID' => account['cid']})
    #     self.logged_in = true
    #   else
    #     clear_login_data
    #   end
    # rescue ConnectionError => e
    #   clear_login_data
    # end
    
    # Returns true if the describe request returned 'LoggedOn'.  Otherwise returns false, and makes sure login data is cleared.
    # def keep_alive
    #   return false unless logged_in?
    #   
    #   response = c.post("/Describe", c.class.wrap_with_header_xml('<describe />'))
    #   result = c.class.decode(response.body)
    #   if result['result']['code'] == '1000'
    #     self.timeout_at = Time.now + result['resdata']['timeout'].to_i
    #     true
    #   else
    #     clear_login_data
    #   end
    # end
    # alias_method :describe, :keep_alive
    
    # # Calls keep_alive and raises an error if false. 
    # def keep_alive!
    #   unless keep_alive
    #     raise GodaddyResellerError("logged out") 
    #   end
    # end
    # alias_method :describe!, :keep_alive!
    # 
    # def logged_in?
    #   self.logged_in # && !session_expired? this is the old API
    # end
    # 
    # def session_expired?
    #   Time.now < self.timeout_at && Time.now < self.expires_at
    # end
    
    
    protected
      # clears all pertainant login data, and returns false (for chaining or returning)
      def clear_login_data
        self.account = nil
        # c.update_cookies({'JSESSIONID' => nil})
        self.timeout_at = nil
        self.expires_at = nil
        self.logged_in = false
      end
  end
end