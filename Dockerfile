FROM alpine:latest

# Install Nginx for full modern MIME type support
RUN apk add --no-cache nginx

# Create deployment directory
WORKDIR /usr/share/nginx/html

# Clean out default landing files
RUN rm -rf ./*

# Copy the static web build artifacts directly into nginx's public root
COPY . .

# Expose port 80 internally
EXPOSE 80

# Run Nginx persistently in the foreground
CMD ["nginx", "-g", "daemon off;"]