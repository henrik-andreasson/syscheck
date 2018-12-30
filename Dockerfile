# Use an official Python runtime as a parent image
FROM centos:latest

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages
RUN yum install -y ruby-devel gcc make rpm-build rubygems

RUN gem install --no-ri --no-rdoc fpm

# Make port 80 available to the world outside this container
# EXPOSE 80

# Define environment variable
ENV SYSCHECK_HOME /opt/syscheck

# Run app.py when the container launches
CMD [ "./test/run-build-install-and-test.sh", "/app", "/opt/syscheck" ]
