require 'redd'
require 'discordrb'
require 'yaml'

SP_REGEX = /.+\|.+-.+\[.+\]/  # This is what a score post looks like.
UP = "\u{1F44D}"
DOWN = "\u{1F44E}"

post_ids = File.join(Dir.home, 'score-post-notifier', 'posts')
config = YAML.load_file(File.join(Dir.home, 'score-post-notifier', 'config.yml'))

ids = []
begin
  File.open(post_ids) {|f| ids = Marshal.load(f.read)}
rescue
end

discord = Discordrb::Bot.new(
  client_id: config['discord_client_id'],
  token: config['discord_token'],
)
discord.run(:async)

Redd.it(
  user_agent: 'osu!-bot',
  client_id: config['reddit_client_id'],
  secret: config['reddit_secret'],
  username: 'osu-bot',
  password: config['reddit_password'],
).subreddit('osugame').new.each do |post|
  if post.title.strip =~ SP_REGEX && !post.is_self && !ids.include?(post.id)
    ids.push(post.id)
    config['discord_channel_ids_to_roles'].each do |channel, role|
      msg = discord.send_message(
        channel, "#{role}: #{post.title}\nhttps://redd.it/#{post.id}"
      )
      msg.react(UP)
      msg.react(DOWN)
    end
    puts("Sent a message for post: redd.it/#{post.id}")
  end
end

File.open(post_ids, 'w') {|f| f.write(Marshal.dump(ids))}
