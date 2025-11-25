# Use official Ruby image
FROM ruby:3.3.5-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the rest of the application
COPY . .

# Expose port 3003
EXPOSE 3003

# Start the server on port 3003
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3003"]
