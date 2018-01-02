FROM golang:latest
ENV APP /go/src/github.com/christopher-dG/score-post-notifier
ADD . $APP
ENV SPN_CONFIG $APP/config.json
WORKDIR $APP
RUN go get ./... && go build
ENV PATH $PATH:$APP
ENTRYPOINT ["entrypoint.sh"]
