module GoDaddyReseller 
  # This module helps with the api reseller certification process, and is not normally needed.
  module Certification
    
    # Runs the 7 certification tasks
    #  - Domain name availability check 
    #  - Domain name registration 
    #  - Domain name privacy purchase 
    #  - Domain name availability check 
    #  - Domain name information query 
    #  - Domain name renewal 
    #  - Domain name transfer 
    def run_certification
      
    end
    
    # Resets the certification tasks, in case something went wrong during certification
    def reset_certification_run
      response = process_request("<manage><script cmd='reset' /></manage>")
      result = c.class.soap_response_text(response.body)

      if result == 'scripting status reset'
        true
      else
        false
      end
    end
  end
end