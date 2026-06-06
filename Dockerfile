FROM nginx:alpine

# Clean out the default Nginx placeholder files
RUN rm -rf /usr/share/nginx/html/*

# Copy your static web build files into Nginx's public root
COPY . /usr/share/nginx/html

# Overwrite Nginx default config to explicitly register .mjs as JavaScript
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
        \
        # Force Nginx to map .mjs modules correctly \
        types { \
            application/javascript mjs; \
        } \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80