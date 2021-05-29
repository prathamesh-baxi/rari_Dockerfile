FROM golang:1.14.4-stretch AS builder

LABEL maintainer="Free5GC <support@free5gc.org>"

# dep
RUN apt-get update \
    && apt-get -y install gcc cmake autoconf libtool pkg-config libmnl-dev libyaml-dev apt-transport-https ca-certificates \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y nodejs yarn


RUN apt-get clean

# clone free5c
RUN cd $GOPATH/src \
    && git clone --recursive -b v3.0.5 -j `nproc` https://github.com/free5gc/free5gc.git

# free5gc build/make NFs
RUN cd $GOPATH/src/free5gc \
    && make all


FROM alpine

WORKDIR /free5gc
RUN mkdir -p config/ support/TLS/ public

# executables
COPY --from=builder /go/src/free5gc/bin/* ./
COPY --from=builder /go/src/free5gc/NFs/upf/build/bin/* ./
COPY --from=builder /go/src/free5gc/webconsole/bin/webconsole ./webui

# static files (webui frontend)not necessary
COPY --from=builder /go/src/free5gc/webconsole/public ./public

# linked libs
COPY --from=builder /go/src/free5gc/NFs/upf/build/updk/src/third_party/libgtp5gnl/lib/libgtp5gnl.so.0 ./
COPY --from=builder /go/src/free5gc/NFs/upf/build/utlt_logger/liblogger.so ./

# # config files (not used for now)
# COPY --from=builder /go/src/free5gc/config/* ./config/
# COPY --from=builder /go/src/free5gc/NFs/upf/build/config/* ./config/

# # Copy default certificates (not used for now)
# COPY --from=builder /go/src/free5gc/support/TLS/* ./support/TLS/
