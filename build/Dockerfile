FROM gcr.io/cloud-builders/git as downloader
ARG HUGO_VERSION="0.58.3"

ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz /
RUN  tar -xvzf hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /

FROM alpine:latest
ENV PORT 8080
COPY --from downloader /hugo /usr/bin/hugo
COPY gleich.dev /gleich.dev
COPY build/run.sh /run.sh
CMD ['/run.sh']