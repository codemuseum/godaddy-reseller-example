module GoDaddyReseller 
  module Domains
    
    def self.included(base) # :nodoc:
      base.class_eval do
        attr_accessor :orders
      end
    end
    
    # Turns a result of a check routine to a hash of domain names with true, false, or :error.  Broken out mostly to test it.
    def self.check_result_to_answer(result)
      answer = {}
      
      domain_results = result['resdata']['check']['domain'].is_a?(Hash) ? 
                            [ result['resdata']['check']['domain'] ] : result['resdata']['check']['domain']
                            
      domain_results.each do |domain_hash|
        answer[domain_hash['name'].to_s] = case domain_hash['avail'].to_s
        when '0'
          false
        when '1'
          true
        when '-1'
          :error
        end
      end
      
      answer
    end
    
    # Executes the call to see if the domains provided are available, returning a hash with true, false, or :error
    def check(domains_array)
      keep_alive!
      
      response = c.post("/Check", { :check => { :domain => domains_array.map { |d| {:_attributes => { :name => d }}} }})
      result = c.class.decode(response.body)
      if result['result']['code'] == '1000'
        self.class.check_result_to_answer(result)
      else
        raise GoDaddyResellerError(result['result']['msg'])
      end
    end

    # This takes quite the hash. See spec/domains_spec.rb for example order_hashes
    # Returns an order response hash {:user_id => '2', :dbpuser_id => '3', :order_id => '100' }, or raises an error if there was a problem.
    def order(order_hash)
      keep_alive!
      
      response = c.post("/Order", order_hash)
      result = c.class.decode(response.body)
      if result['result']['code'] == '1000'
        self.orders ||= []
        self.orders << { :user_id => result['user'], :dbpuser_id => result['dbpuser'], :order_id => result['resdata']['orderid'] }
        return self.orders.last
      else
        raise GoDaddyResellerError(result['result']['msg'])
      end
    end
    
    protected

      
  end
end