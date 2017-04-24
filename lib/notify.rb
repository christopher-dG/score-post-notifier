require 'redd'
require 'discordrb'

DIR = File.expand_path("#{File.expand_path(__FILE__)}/../..")
POSTS_FILE = "#{DIR}/posts"
SECRETS_DIR = "#{DIR}/secrets"
D_TOKEN = File.open("#{SECRETS_DIR}/d_token") {|f| f.read.chomp}
D_CLIENT_ID = File.open("#{SECRETS_DIR}/d_client_id") {|f| f.read.chomp}
CHANNEL_ID = File.open("#{SECRETS_DIR}/d_channel_id") {|f| f.read.chomp}
R_PASSWORD = File.open("#{SECRETS_DIR}/r_pass").read.chomp
R_SECRET = File.open("#{SECRETS_DIR}/r_secret").read.chomp
R_CLIENT_ID=File.open("#{SECRETS_DIR}/r_client_id").read.chomp

discord = Discordrb::Bot.new token: D_TOKEN, client_id: D_CLIENT_ID
discord.run(:async)

begin
  posts = Marshal.load(File.open(POSTS_FILE).read)
rescue
  posts = []
end

Redd.it(
  user_agent: 'Redd:osu!-bot:v0.0.0',
  client_id: R_CLIENT_ID,
  secret: R_SECRET,
  username: 'osu-bot',
  password: R_PASSWORD,
).subreddit('osugame').new.each do |post|
  if post.title.strip =~ /.+\|.+-.+\[.+\].*/ && !post.is_self &&
     !posts.include?(post.permalink)
    posts.push(post.permalink)
    discord.send_message(CHANNEL_ID, "@here New score post: https://reddit.com#{post.permalink}")
  end
end

File.open(POSTS_FILE, 'w') {|f| f.write(Marshal.dump(posts))}
