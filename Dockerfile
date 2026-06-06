FROM nginx:alpine

# Clean out default Nginx landing files
RUN rm -rf /usr/share/nginx/html/*

# Copy your static web build files into Nginx's public root
COPY . /usr/share/nginx/html

# Inject the .mjs mapping directly into the top of the global mime.types registry
RUN sed -i 's|types {|types {\n    application/javascript mjs;|' /etc/nginx/mime.types

EXPOSE 80
