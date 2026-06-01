FROM ubuntu:22.04

# Install SSH and other tools
RUN apt-get update && apt-get install -y openssh-server sudo && \
    mkdir /var/run/sshd

# Create user
RUN useradd -m -s /bin/bash user && \
    echo 'user:user' | chpasswd

# Set up flags
RUN echo "FEIT{korisnik4_fs_hidden_5532}" > /home/user/.hidden_flag && \
    chown user:user /home/user/.hidden_flag

RUN echo "FEIT{korisnik4_fs_permissions_5532}" > /opt/secret.txt && \
    chmod 444 /opt/secret.txt

RUN echo "FEIT{korisnik4_fs_privesc_flag_5532}" > /root/flag.txt && \
    chmod 400 /root/flag.txt

# Create a SUID binary (simple wrapper for cat)
RUN echo '#include <stdio.h>\n#include <stdlib.h>\n#include <unistd.h>\nint main() { setuid(0); system("cat /root/flag.txt"); return 0; }' > /tmp/suid.c && \
    apt-get install -y gcc && \
    gcc /tmp/suid.c -o /usr/local/bin/read_flag && \
    chmod 4755 /usr/local/bin/read_flag && \
    rm /tmp/suid.c && \
    apt-get purge -y gcc && \
    apt-get autoremove -y

# Configure SSH
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Port 2224
RUN sed -i 's/#Port 22/Port 2224/' /etc/ssh/sshd_config

EXPOSE 2224
CMD ["/usr/sbin/sshd", "-D"]
