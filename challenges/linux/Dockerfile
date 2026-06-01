FROM ubuntu:22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    nano \
    vim \
    curl \
    wget \
    net-tools \
    iproute2 \
    htop \
    bash-completion \
    fail2ban \
    iptables \
    rsyslog \
    && rm -rf /var/lib/apt/lists/*

# Configure fail2ban for SSH
RUN echo "[sshd]\n\
enabled = true\n\
port = ssh\n\
filter = sshd\n\
logpath = /var/log/auth.log\n\
maxretry = 5\n\
bantime = 1800\n\
findtime = 600" > /etc/fail2ban/jail.local

# Setup SSH
RUN mkdir /var/run/sshd
# Disable root login
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
# Restrict SSH to only our challenge users
RUN echo "AllowUsers m3 korisnik2 korisnik3 korisnik4 demurehakerz" >> /etc/ssh/sshd_config

# Create users and set passwords using build args for security
ARG PASS_M3=RandomForest
ARG PASS_KORISNIK2=Securepassword
ARG PASS_KORISNIK3=Passwordpassword
ARG PASS_KORISNIK4=Scoopaffogato
ARG PASS_DEMUREHAKERZ=Zhapongallery

RUN useradd -m -s /bin/bash m3 && echo "m3:${PASS_M3}" | chpasswd && chmod 700 /home/m3 && \
    useradd -m -s /bin/bash korisnik2 && echo "korisnik2:${PASS_KORISNIK2}" | chpasswd && chmod 700 /home/korisnik2 && \
    useradd -m -s /bin/bash korisnik3 && echo "korisnik3:${PASS_KORISNIK3}" | chpasswd && chmod 700 /home/korisnik3 && \
    useradd -m -s /bin/bash korisnik4 && echo "korisnik4:${PASS_KORISNIK4}" | chpasswd && chmod 700 /home/korisnik4 && \
    useradd -m -s /bin/bash demurehakerz && echo "demurehakerz:${PASS_DEMUREHAKERZ}" | chpasswd && chmod 700 /home/demurehakerz

# Setup the kick script
COPY src/kick_competitor.sh /usr/local/bin/kick_competitor
RUN chmod 755 /usr/local/bin/kick_competitor

# Allow users to run the kick script and read auth logs as root without a password
RUN echo "m3 ALL=(root) NOPASSWD: /usr/local/bin/kick_competitor, /usr/bin/tail -f /var/log/auth.log, /usr/bin/tail /var/log/auth.log, /usr/bin/cat /var/log/auth.log, /usr/bin/fail2ban-client" > /etc/sudoers.d/ctf_kick && \
    echo "korisnik2 ALL=(root) NOPASSWD: /usr/local/bin/kick_competitor, /usr/bin/tail -f /var/log/auth.log, /usr/bin/tail /var/log/auth.log, /usr/bin/cat /var/log/auth.log, /usr/bin/fail2ban-client" >> /etc/sudoers.d/ctf_kick && \
    echo "korisnik3 ALL=(root) NOPASSWD: /usr/local/bin/kick_competitor, /usr/bin/tail -f /var/log/auth.log, /usr/bin/tail /var/log/auth.log, /usr/bin/cat /var/log/auth.log, /usr/bin/fail2ban-client" >> /etc/sudoers.d/ctf_kick && \
    echo "korisnik4 ALL=(root) NOPASSWD: /usr/local/bin/kick_competitor, /usr/bin/tail -f /var/log/auth.log, /usr/bin/tail /var/log/auth.log, /usr/bin/cat /var/log/auth.log, /usr/bin/fail2ban-client" >> /etc/sudoers.d/ctf_kick && \
    echo "demurehakerz ALL=(root) NOPASSWD: /usr/local/bin/kick_competitor, /usr/bin/tail -f /var/log/auth.log, /usr/bin/tail /var/log/auth.log, /usr/bin/cat /var/log/auth.log, /usr/bin/fail2ban-client" >> /etc/sudoers.d/ctf_kick && \
    chmod 440 /etc/sudoers.d/ctf_kick

# Add a MOTD hint
RUN echo "\nWelcome to the FEIT Linux Admin Challenge.\nFind your flag hidden in the filesystem.\nHint: Use 'sudo kick_competitor <username>' to terminate another team's session.\n" > /etc/motd
RUN sed -i 's/#PrintMotd yes/PrintMotd yes/' /etc/ssh/sshd_config
# Disable PrintLastLog to make motd cleaner
RUN sed -i 's/#PrintLastLog yes/PrintLastLog no/' /etc/ssh/sshd_config

# Disable rsyslog message reduction so fail2ban sees every line
RUN sed -i 's/\$RepeatedMsgReduction on/\$RepeatedMsgReduction off/' /etc/rsyslog.conf

# Create utmp and wtmp to ensure 'who' and 'w' commands work
RUN touch /var/run/utmp /var/log/wtmp /var/log/lastlog && \
    chmod 664 /var/run/utmp /var/log/wtmp /var/log/lastlog

EXPOSE 22

# Ensure utmp exists and start rsyslog, fail2ban, and sshd
CMD ["/bin/sh", "-c", "touch /var/run/utmp /var/log/wtmp /var/log/lastlog /var/log/auth.log && chown syslog:adm /var/log/auth.log && /usr/sbin/rsyslogd && /etc/init.d/fail2ban start && /usr/sbin/sshd -D"]