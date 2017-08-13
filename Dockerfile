FROM ruby:2.4.1

ENV APP /root/app
ENV GEMS discordrb redd

RUN mkdir $APP && \
    gem install $GEMS

COPY . $APP

CMD ["ruby", "/root/app/lib/notify.rb"]
