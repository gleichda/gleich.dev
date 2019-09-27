FROM alpine:latest as downloader
ARG HUGO_VERSION="0.58.3"
ARG hugo_args=""

ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz /
RUN  tar -xvzf hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /
COPY build/run.sh /run.sh
RUN chmod +x /run.sh
COPY gleich.dev /gleich.dev
WORKDIR /gleich.dev
RUN /hugo ${hugo_args}



FROM busybox:1.31.0
ENV PORT 8080
COPY --from=downloader /run.sh /run.sh
COPY --from=downloader /hugo /usr/bin/hugo
COPY --from=downloader /gleich.dev/public /public
ENTRYPOINT '/run.sh'
