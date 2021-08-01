From jrei/systemd-fedora

RUN dnf update -y
RUN dnf install -y freeipa-client bash vim iputils findutils net-tools mariadb-server

COPY mokey-0.5.6-1.el7.x86_64.rpm /
RUN dnf install -y /mokey-0.5.6-1.el7.x86_64.rpm

COPY install.sh /
RUN chmod a+x /install.sh

CMD ["/usr/sbin/init"]

