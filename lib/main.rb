require_relative 'consts'
require_relative 'disccord'
require_relative 'reddit'

def log(msg='', n=10)
  if msg.empty?
    for file in `ls #{LOG_DIR} | tail -#{n}`.split("\n")
      File.open(File.expand_path("#{LOG_DIR}/#{file}")) {|f| puts("#{file}:\n#{f.read}----")}
    end
  else
    File.open("#{LOG_DIR}/#{now}", 'a') {|f| f.write(msg)}
  end
end

def now
  return `date +"%m-%d-%Y_%H:%M"`.chomp
end
