# Use an official Python runtime as a parent image
FROM centos-cs:latest

# Set the working directory to /app
WORKDIR /source
COPY . /source

# Install any needed packages
RUN yum install -y ruby-devel gcc make rpm-build rubygems git

RUN gem install --no-ri --no-rdoc fpm

# Make port 80 available to the world outside this container
# EXPOSE 80

# Define environment variable
ENV SYSCHECK_HOME /opt/syscheck

# Run when the container launches
CMD [ "/source/test/run-build-install-and-test.sh", "/source", "/opt/syscheck" , "/results" , "/work"]
