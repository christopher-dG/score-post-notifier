FROM ruby:latest
ENV CONFIG /root/app/config.yml
RUN gem install discordrb redd
COPY . /root/app
CMD ["ruby", "/root/app/notify.rb"]
