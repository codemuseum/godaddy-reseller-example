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
    
    # Turns a result of a check routine to an array of order hashes 
    # [ { :orderid => '100', :items => [ { :riid => '1', :resourceid => 'domain:1', :statuses => [{ :id => '1', :timestamp =>  }] } ] }].  
    # Broken out mostly to test it.
    def self.poll_result_to_order_hash(result)
      order_array = []
      
      item_results = result['resdata']['report']['item'].is_a?(Hash) ? 
                            [ result['resdata']['report']['item'] ] : result['resdata']['report']['item']
      
      item_results.each do |item_hash|
        order = order_array.detect {|o| o[:orderid] == item_hash['orderid'] }
        unless order
          order_array << { :orderid => item_hash['orderid'], :items => [] }
          order = order_array.last
        end
        order[:roid] = item_hash['roid'] unless item_hash['roid'].blank?
        
        item = order[:items].detect {|i| i[:riid] == item_hash['riid'] }
        unless item
          order[:items] << { :riid => item_hash['riid'], :statuses => [] }
          item = order[:items].last
        end
        
        item[:statuses] << { :id => item_hash['status'], :timestamp => Time.parse(item_hash['timestamp']) }
        item[:resourceid] = item_hash['resourceid'] unless item_hash['resourceid'].blank?
      end
      
      order_array
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
    # Returns an order response hash {:user_id => '2', :dbpuser_id => '3', :orderid => '100' }, or raises an error if there was a problem.
    def order(order_hash)
      keep_alive!
      
      response = c.post("/Order", order_hash)
      result = c.class.decode(response.body)
      if result['result']['code'] == '1000'
        self.orders ||= []
        self.orders << { :user_id => result['user'], :dbpuser_id => result['dbpuser'], :orderid => result['resdata']['orderid'] }
        return self.orders.last
      else
        raise GoDaddyResellerError(result['result']['msg'])
      end
    end
    
    # Requests all orders from the reseller server, and returns an array of hashes, containing one ore more orders, 
    # each with items
    # [ { :orderid => '100', :items => [ { :resourceid => 'domain:1', :statuses => [{ :id => '1', :timestamp =>  }] } ] }]
    def poll
      keep_alive!
      
      response = c.post("/Poll", :poll => { :_attributes => { :op => 'req'}})
      result = c.class.decode(response.body)
      
      if result['result']['code'] == '1000'
        self.class.poll_result_to_order_hash(result)
        
      else
        raise GoDaddyResellerError(result['result']['msg'])
      end
      
      
      
    end
    
    protected

      
  end
end