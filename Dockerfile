# Use Ruby 3.3.1 as the base image
FROM ruby:3.3.1

# Install dependencies for the gruff gem
RUN apt-get update && apt-get install -y libsqlite3-dev libmagickwand-dev cron

# Set the working directory inside the container
WORKDIR /app

# Install required gems
RUN gem install sqlite3 gruff

# Copy the Ruby script into the container
COPY script.rb /app/
COPY crontab /etc/cron.d/crontab


RUN chmod 0644 /etc/cron.d/crontab
RUN crontab /etc/cron.d/crontab
RUN touch /var/log/cron.log

CMD cron && tail -f /var/log/cron.log
