require 'redd'

SECRETS_DIR = File.expand_path("#{File.dirname(__FILE__)}/secrets")
R_PASSWORD = File.open("#{SECRETS_DIR}/r_pass").read.chomp
R_SECRET = File.open("#{SECRETS_DIR}/r_secret").read.chomp
R_CLIENT_ID_ID=File.open("#{SECRETS_DIR}/r_client_id").read.chomp

osugame = Redd.it(
  user_agent: 'Redd:osu!-bot:v0.0.0',
  client_id: R_CLIENT_ID,
  secret: R_SECRET,
  username: 'osu-bot',
  password: R_PASSWORD,
).subreddit('osugame')
