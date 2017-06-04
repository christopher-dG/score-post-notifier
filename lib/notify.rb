require 'redd'
require 'discordrb'
require 'yaml'

post_ids = File.join(Dir.home, 'score-post-notifier', 'posts')
config = YAML.load_file(File.join(Dir.home, 'score-post-notifier', 'config.yml'))

ids = []
begin
  File.open(post_ids) {|f| ids = Marshal.load(f.read)}
rescue
end

discord = Discordrb::Bot.new(
  token: config['discord_token'],
  client_id: config['discord_client_id']
)
discord.run(:async)

Redd.it(
  user_agent: 'Redd:osu!-bot:v0.0.0',
  client_id: config['reddit_client_id'],
  secret: config['reddit_secret'],
  username: 'osu-bot',
  password: config['reddit_password'],
).subreddit('osugame').new.each do |post|
  if post.title.strip =~ /.+\|.+-.+\[.+\].*/ && !post.is_self && !ids.include?(post.id)
    ids.push(post.id)
    discord.send_message(
      config['discord_channel_id'],
      "@here: #{post.title}\nhttps://redd.it/#{post.id}"
    )
    puts("Sent a message for post: redd.it/#{post.id}")
  end
end

File.open(post_ids, 'w') {|f| f.write(Marshal.dump(ids))}
