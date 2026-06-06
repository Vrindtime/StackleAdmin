FROM alpine:latest

# Install a tiny, highly efficient static web server
RUN apk add --no-cache thttpd

# Create workspace directory
WORKDIR /app

# Copy the static web build artifacts from your current folder into the container
COPY . /app

# Run the static server on container port 80
CMD ["thttpd", "-D", "-p", "80", "-d", "/app", "-u", "root"]