LOG_DIR = File.expand_path("#{File.dirname(File.dirname(__FILE__))/logs}")
SECRETS_DIR = File.expand_path("#{File.dirname(File.dirname(__FILE__))/secrets}")

D_TOKEN = File.open("#{SECRETS_DIR}/d_token") {|f| f.read.chomp}
D_CLIENT_ID = File.open("#{SECRETS_DIR}/d_client_id") {|f| f.read.chomp}
CHANNEL_ID = File.open("#{SECRETS_DIR}/d_channel_id") {|f| f.read.chomp}
CHANNEL = 'botspam'  # Name of the channel that the bot operates in.
THRESHOLD = '10'  # Minutes between Discord message and escalation to AWS EC2.


R_PASSWORD = File.open("#{SECRETS_DIR}/r_pass").read.chomp
R_SECRET = File.open("#{SECRETS_DIR}/r_secret").read.chomp
R_CLIENT_ID=File.open("#{SECRETS_DIR}/r_client_id").read.chomp
