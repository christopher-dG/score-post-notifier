require 'discordrb'

SECRETS_DIR = File.expand_path("#{File.dirname(__FILE__)}/secrets")
D_TOKEN = File.open("#{SECRES_DIR}/d_token") {|f| f.read.chomp}
D_CLIENT_ID = File.open("#{SECRES_DIR}/d_client_id") {|f| f.read.chomp}

discord = Discordrb::Bot.new token: R_TOKEN, client_id: D_CLIENT_ID
