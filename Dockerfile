# Use the official Ruby image from Docker Hub with the desired version
FROM ruby:3.3.3-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        default-mysql-server \
        default-libmysqlclient-dev \
        build-essential \
        patch \
        ruby-dev \
        zlib1g-dev \
        liblzma-dev \
        curl \
        gnupg2 \
        dirmngr \
        nodejs \
        cron

# Set working directory in the container
WORKDIR /app

# Copy Gemfile and Gemfile.lock into the container
COPY Gemfile Gemfile.lock ./

# Install Ruby gems
RUN gem install bundler
RUN bundle install --jobs "$(nproc)" --retry 5

# Copy the rest of the application code into the container
COPY . .

# Expose port 3000 to the Docker network
EXPOSE 3000
