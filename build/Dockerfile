FROM alpine:latest as downloader
ARG HUGO_VERSION="0.68.3"
ARG hugo_args=""

ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz /
RUN  tar -xvzf hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C / && mkdir /binaries && cp /hugo /binaries/hugo 
COPY build/run.sh /binaries/run.sh
RUN chmod +x /binaries/run.sh
COPY gleich.dev /gleich.dev
WORKDIR /gleich.dev
RUN /hugo ${hugo_args}



FROM busybox:1.31.1
ENV PORT 8080
COPY --from=downloader /binaries/* /usr/bin/
COPY --from=downloader /gleich.dev/public /public
ENTRYPOINT '/usr/bin/run.sh'
