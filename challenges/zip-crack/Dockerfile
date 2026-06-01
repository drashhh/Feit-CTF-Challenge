FROM nginx:alpine

# Install zip to create the archive
RUN apk add --no-cache zip

# Set flag
ARG FLAG="FEIT{korisnik2_zip_crack_flag_7231}"

# Create the flag file and zip it with a weak password
RUN echo "${FLAG}" > /flag.txt && \
    zip -P "password123" /usr/share/nginx/html/flag.zip /flag.txt && \
    rm /flag.txt

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
