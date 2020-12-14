# An example Dockerfile for installing Git on Ubuntu
FROM ubuntu:latest
LABEL maintainer="anutech2001@gmail.com"
RUN apt-get update && apt-get install -y git
ENTRYPOINT ["git"]