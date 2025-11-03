# Use an official Python runtime as a parent image
FROM debian:latest

# Set the working directory to /app
WORKDIR /source
COPY . /source

RUN apt update -y
RUN apt install -y gcc make ruby-rubygems git

RUN gem install fpm


# Define environment variable
ENV SYSCHECK_HOME=/opt/syscheck

# Run when the container launches
CMD [ "/source/test/run-build-install-and-test.sh", "/source", "/opt/syscheck" , "/results" , "/work"]
