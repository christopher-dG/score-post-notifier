require 'redd'
require 'discordrb'
require 'yaml'

SP_REGEX = /.+\|.+-.+\[.+\]/  # This is what a score post looks like.
UP = "\u{1F44D}"  # Thumbs up.
DOWN = "\u{1F44E}"  # Thumbs down.

config = YAML.load_file(ENV['CONFIG'])

discord = Discordrb::Bot.new(
  client_id: config['discord_client_id'],
  token: config['discord_token'],
)

subreddit = Redd.it(
  user_agent: 'osu!-bot',
  client_id: config['reddit_client_id'],
  secret: config['reddit_secret'],
  username: 'osu-bot',
  password: config['reddit_password'],
).subreddit('osugame')

discord.run(:async)

# Collect all the IDs of current posts, we don't want to post them
# because we don't know if they've already been posted or not.
ids = subreddit.new(limit: 100).map {|p| p.id}
loop do
  begin
    subreddit.post_stream do |post|
      if post.title.strip =~ SP_REGEX && !post.is_self && !ids.include?(post.id)
        ids.push(post.id)
        player_name = post.title.split('|')[0].strip

        config['channels'].each do |channel|
          submitter_blacklisted = channel['submitter_blacklist'].include?(post.author.name)
          player_blacklisted = channel['player_blacklist'].include?(player_name)

          if !submitter_blacklisted && !player_blacklisted
            text = "#{channel['tag']}: #{post.title}\nhttps://redd.it/#{post.id}"
            puts "Sending to #{channel['id']}:\n#{text}"
            msg = discord.send_message(channel['id'], text)
            msg.react(UP)
            msg.react(DOWN)
          end
        end
      else
        puts "Skipping #{post.id}: #{post.title}"
      end
    end
  rescue => e
    puts("Exception: #{e}")
  end
end
