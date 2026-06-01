FROM ubuntu:22.04

# Install SSH, FTP and other tools
RUN apt-get update && apt-get install -y openssh-server vsftpd && \
    mkdir /var/run/sshd

# Create user
RUN useradd -m -s /bin/bash user && \
    echo 'user:password123' | chpasswd

# Set up flags
RUN echo "FEIT{korisnik5_brute_force_ftp_1198}" > /home/user/ftp_flag.txt && \
    echo "FEIT{korisnik5_brute_force_ssh_1198}" > /home/user/ssh_flag.txt && \
    chown user:user /home/user/ftp_flag.txt /home/user/ssh_flag.txt

# Configure SSH
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 2226/' /etc/ssh/sshd_config

# Configure FTP
RUN sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf && \
    sed -i 's/#local_enable=YES/local_enable=YES/' /etc/vsftpd.conf && \
    sed -i 's/#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf && \
    echo "seccomp_sandbox=NO" >> /etc/vsftpd.conf && \
    echo "local_root=/home/user" >> /etc/vsftpd.conf

# Create startup script
RUN echo '#!/bin/bash\n/usr/sbin/sshd\n/usr/sbin/vsftpd /etc/vsftpd.conf' > /start.sh && \
    chmod +x /start.sh

EXPOSE 21 2226
CMD ["/start.sh"]
