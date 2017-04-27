FROM debian:latest
#FROM alpine:latest

#RUN apk update && \
#    apk upgrade && \
#    apk add --update --no-cache nrpe nrpe-plugin nagios-plugins-all openssl python perl bash curl wget gawk sed jq vim && \
#    rm /var/cache/apk/* 
#ENV NAGIOS_CONF_DIR /etc
RUN echo 'deb http://httpredir.debian.org/debian jessie-backports main contrib non-free' > /etc/apt/sources.list.d/jessie-backports.list
#RUN echo 'deb http://httpredir.debian.org/debian sid main contrib non-free' > /etc/apt/sources.list.d/jessie-sid.list

RUN apt-get update \
    && apt-get upgrade -q -y \
    && apt-get install -q -y nagios-nrpe-server nagios-plugins nagios-plugins-* sudo curl wget perl python openssl php5 gawk sed jq vim bc \
                             libdatetime-format-strptime-perl libnagios-plugin-perl libhtml-strip-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt /tmp/* /var/tmp/*

RUN echo 'deb http://httpredir.debian.org/debian sid main contrib non-free' > /etc/apt/sources.list.d/jessie-sid.list
RUN apt-get update -q -y && apt-get install -q -y -t sid curl
RUN rm -rf /etc/apt/sources.list.d/jessie-sid.list && apt-get clean && apt-get update -q -y

ENV NAGIOS_CONF_DIR /etc/nagios
ENV NAGIOS_PLUGINS_DIR /usr/lib/nagios/plugins
ENV DUMB_INIT_VERSION 1.2.0

#RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v"$DUMB_INIT_VERSION"/dumb-init_"$DUMB_INIT_VERSION"_amd64 && \
#    chmod +x /usr/local/bin/dumb-init

#RUN mkdir -p /etc/nrpe.d
RUN sed -e 's/^allowed_hosts=/#allowed_hosts=/' -i $NAGIOS_CONF_DIR/nrpe.cfg \
    && echo "command[check_load]=$NAGIOS_PLUGINS_DIR/check_load -w 15,10,5 -c 30,25,20" > $NAGIOS_CONF_DIR/nrpe.d/load.cfg \
    && echo "command[check_mem]=$NAGIOS_PLUGINS_DIR/check_mem -u -C -w 80 -c 90" > $NAGIOS_CONF_DIR/nrpe.d/mem.cfg \
    && echo "command[check_total_procs]=/usr/lib/nagios/plugins/check_procs -w 500 -c 700 " > $NAGIOS_CONF_DIR/nrpe.d/procs.cfg

ENV ETCDCTL_VERSION v2.2.5
RUN curl -L https://github.com/coreos/etcd/releases/download/$ETCDCTL_VERSION/etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz -o /tmp/etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz && \
    cd /tmp && gzip -dc etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz | tar -xof - && \
    cp -f /tmp/etcd-$ETCDCTL_VERSION-linux-amd64/etcdctl /usr/local/bin && \
    rm -rf /tmp/etcd-$ETCDCTL_VERSION-linux-amd64.tar.gz

ADD run-nrpe.sh /usr/sbin/run-nrpe.sh
RUN chmod +x /usr/sbin/run-nrpe.sh

ADD plugins $NAGIOS_PLUGINS_DIR
RUN chmod +x -R  $NAGIOS_PLUGINS_DIR

ADD nrpe.d $NAGIOS_CONF_DIR/nrpe.d

EXPOSE 5666

CMD ["/usr/sbin/run-nrpe.sh"]
