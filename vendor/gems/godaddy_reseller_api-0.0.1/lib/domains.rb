module GoDaddyReseller 
  module Domains
    
    def self.included(base) # :nodoc:
      base.class_eval do
        attr_accessor :orders, :manages
      end
    end
    
    # Turns a result of a check request to a hash of domain names with true, false, or :error.  Broken out mostly to test it.
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
    
    # Turns a result of a info request to a hash of domain names with all necessary values.  Broken out mostly to test it.
    # { 'example.com' =>  {:resourceid, :autoRenewDate, :ownerID, :expirationDate, :status, :private }}
    def self.info_result_to_hash(result)
      hash = {}
      
      domain_results = result['resdata']['info'].is_a?(Hash) ? 
                            [ result['resdata']['info'] ] : result['resdata']['info']
            
      domain_results.each do |domain_hash|
        domain_name = domain_hash.delete('name').to_s.downcase
        converted_hash = {}
        domain_hash.each_pair do |k,v|
          converted_hash[k.to_sym] = case k
          when 'auto_renew_date'
            v.blank? ? v : Time.parse(v)
          when 'expiration_date'
            v.blank? ? v : Time.parse(v)
          when 'private'
            v == 'yes' ? true : false
          when 'status'
            v.to_i
          else
            v
          end
        end

        hash[domain_name] = converted_hash
      end
      
      hash
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
    # Returns an order response hash {:user_id => '2', :dbpuser_id => '3', :orderid => '100' }, 
    # or raises an error if there was a problem.
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
    
    # Checks the information for all domains (up to 100) in the array.
    # This is a slight deviation from all the options the API provides, in that you can request by resourceid or orderid,
    # but domain names are just so much easier!
    # Returns a hash with information for each. 
    # { 'example.com' =>  {:resourceid, :autoRenewDate, :ownerID, :expirationDate, :status, :private }} 
    def info(domains_array, type = 'standard')
      keep_alive!
      
      response = c.post("/Info", { :info => domains_array.map { |d| {:_attributes => { :domain => d, :type => type }}} })
      result = c.class.decode(response.body)
      if result['result']['code'] == '1000'
        self.class.info_result_to_hash(result)
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

    # Convenience method on top of the manage api call, for cancelling an item
    def cancel(resourceid, type = 'deferred')
      manage(:manage => { :cancel => { 
        :_attributes => { :type => type },
        :id => resourceid
      }})
    end
    
    # Takes a setting for whether or not the domain should be locked (boolean), and sends the request to mark the
    # domain as such. Returns the response message, or raises an error if there was a problem.
    def modify_lock(locked, resourceid, manager_transaction_id)
      keep_alive!
      
      manage_hash = { :manage => { :setLocking => { 
        :_attributes => { :lock => (locked ? :yes : :no) }, 
        :domain => { :resourceid => resourceid, :mngTRID => manager_transaction_id } 
      }}}
      
      response = c.post("/manage/domains/setLocking", manage_hash)
      result = c.class.decode(response.body)
      if result['result']['code'] == '1000'
        self.manages ||= []
        self.manages << result['resdata']
        return self.manages.last
      else
        raise GoDaddyResellerError(result['result']['msg'])
      end
    end
    
    # This takes quite the hash. See spec/domains_spec.rb for example manage_hashes
    # Returns the response message, or raises an error if there was a problem.
    def manage(manage_hash)
      keep_alive!
      
      response = c.post("/Manage", manage_hash)
      result = c.class.decode(response.body)
      if result['result']['code'] == '1000'
        self.manages ||= []
        self.manages << result['resdata']
        return self.manages.last
      else
        raise GoDaddyResellerError(result['result']['msg'])
      end
    end
    
  end
end