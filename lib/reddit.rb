require 'redd'

def get_sub
  begin
    Redd.it(
      user_agent: 'Redd:osu!-bot:v0.0.0',
      client_id: R_CLIENT_ID,
      secret: R_SECRET,
      username: 'osu-bot',
      password: R_PASSWORD,
    ).subreddit('osugame')
  rescue
    log('Reddit authorization failed.')
    exit
  end
end

def is_score_post(post)
  return post.title.strip =~ /[ -\]\[\w]{3,}\|.*\S.*-.*\S.*\[.*\S.*\]/ && !post.is_self
end

if __FILE__ == $0
  osugame = get_sub
  posts = File.open("#{FILE_DIR}/posts").read.split("|")
  for post in osugame.listing('new', :limit 50)
    # Todo: Look into what happens when the bot runs concurrently.
    # Maybe require the ack to contain a unique token.
    if is_score_post(post) && !posts.include?(post.permalink)
      log("Notifying for post '#{post.title}'.")
      posts.push(post.permalink)
      start_discord
      notify_discord(post.title, post.permalink)
      countdown && ec2(title)
    end
  end
  File.open("#{FILE_DIR}/posts", 'w') {|f| f.write(posts.join("|"))}
end
