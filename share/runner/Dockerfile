FROM docker

RUN apk add --no-cache inotify-tools bash

COPY runner.sh /
WORKDIR /
VOLUME /out
CMD ./runner.sh
