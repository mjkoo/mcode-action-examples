FROM debian:buster-slim as builder1
RUN apt-get update && \
    apt-get install -y gcc make libc6-dbg
COPY mayhemit-c/mayhemit.c .
# complile with coverage
RUN gcc -g mayhemit.c -o /mayhemit

FROM debian:10-slim as builder2
RUN apt-get update && apt-get install -y build-essential wget libc6-dbg autoconf automake libtool pkg-config
WORKDIR /build
RUN wget https://github.com/lighttpd/lighttpd1.4/archive/refs/tags/lighttpd-1.4.52.tar.gz
RUN tar xf lighttpd-1.4.52.tar.gz \
   && cd /build/lighttpd1.4-lighttpd-1.4.52 \
   && ./autogen.sh \
   && CFLAGS=-g ./configure --without-bzip2 --without-pcre --without-zlib --build=x86_64-unknown-linux-gnu \
   && CFLAGS=-g make \
   && CFLAGS=-g make install
COPY lighttpd/lighttpd.conf /usr/local/etc

FROM debian:10-slim
RUN apt-get update && apt-get install -y  --no-install-recommends libc6-dbg
COPY mayhem/testsuite /testsuite
COPY --from=builder1 /mayhemit /mayhemit
COPY --from=builder2 /usr/local /usr/local
RUN mkdir /www && echo "lighttpd 1.4.52 running!" > /www/index.html
CMD ["/usr/local/sbin/lighttpd","-D", "-f","/usr/local/etc/lighttpd.conf"]
EXPOSE 80
