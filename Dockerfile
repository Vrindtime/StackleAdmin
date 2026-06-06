FROM nginx:alpine

# Clean out the default Nginx placeholder files
RUN rm -rf /usr/share/nginx/html/*

# Copy your static files into Nginx's verified public root
COPY . /usr/share/nginx/html

EXPOSE 80