FROM alpine:3.9

RUN apk add --no-cache mariadb-client jq
RUN addgroup -S apiary && adduser -S apiary -G apiary -H

ADD --chown=apiary:apiary *.sh /init/
WORKDIR /init
RUN chmod +x `ls *.sh`
USER apiary

CMD ["/bin/sh"]
