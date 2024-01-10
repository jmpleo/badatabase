FROM debian:bookworm
MAINTAINER Simão Martins "simao.martins@tecnico.ulisboa.pt"

ENV DEBIAN_FRONTEND noninteractive
# The -qq implies --yes
RUN apt update && \
    apt install -y apt-transport-https locales krb5-user && \
    apt clean

RUN locale-gen "en_US.UTF-8"
RUN echo "LC_ALL=\"en_US.UTF-8\"" >> /etc/default/locale

ENV REALM ${REALM:-EXAMPLE.COM}
ENV KADMIN_PRINCIPAL ${KADMIN_PRINCIPAL:-kadmin/admin}
ENV KADMIN_PASSWORD ${KADMIN_PASSWORD:-MITiys4K5}

COPY init-script.sh configureKerberosClient.sh /tmp/
CMD /tmp/init-script.sh
