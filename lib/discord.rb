require 'discordrb'

def get_bot
  Discordrb::Bot.new token: D_TOKEN, client_id: D_CLIENT_ID
end

def start_discord
  bot = get_bot
  bot.message(:starts_with '!ack', :in CHANNEL) do |event|
    event.send_message("Thanks, @#{event.author}.")
    exit
  end
  # bot.start
end

# Notify the Discord channel that a new score has been posted.
def notify_discord(title, permalink)
  msg = "@here new score post: #{title} - https://reddit.com#{permalink}"
  msg += "Type '!ack' within #{THRESHOLD} minutes to acknowledge that "
  msg += "you are uploading this play."
  bot.send_message(CHANNEL_ID, msg)
end

# Wait `THRESHOLD` minutes, or until someeone acks.
def countdown
  # Not sure if `sleep(THRESHOLD_to_i * 60)` would block event handlers.
  log = File.open("#{LOGS_DIR}/#{now}.log") do |f|
    for i in THRESHOLD.to_i * 60
      sleep(1)
      log.write("Response took #{i} seconds).")
    end
    log.write('No reponse.')
  end
  return true
end

# Bring up the EC2 instance and send it the post title.
def ec2(title)
  bot.send_message(CHANNEL_ID, "auto-recorder is recording/uploading '${title}'.")
end
