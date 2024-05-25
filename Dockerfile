# Use Ruby 3.3.1 as the base image
FROM ruby:3.3.1

# Install dependencies for the gruff gem
RUN apt-get update && apt-get install -y libsqlite3-dev libmagickwand-dev

# Set the working directory inside the container
WORKDIR /app

# Install required gems
RUN gem install sqlite3 gruff

# Copy the Ruby script into the container
COPY script.rb /app/

# Set the default command to run the script
CMD ["ruby", "script.rb"]
