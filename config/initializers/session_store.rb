# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_godaddy-reseller-example_session',
  :secret      => '4b22b5105f628c6a1db7daef24bf4d854e645952e161ea1d886be30f5d2ffde4aa892b2edde7c3dc18656a81738405fffa21047d76d51ee1b55454f1139595a8'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
