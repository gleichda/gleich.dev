FROM alpine:latest as downloader
ARG HUGO_VERSION="0.75.1"
ARG hugo_args=""

ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz /
RUN  tar -xvzf hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C / && mkdir /binaries && cp /hugo /binaries/hugo 
COPY gleich.dev /gleich.dev
WORKDIR /gleich.dev
RUN /hugo ${hugo_args}

FROM nginx:stable-alpine
ENV PORT 8080
ENV BASE_DOMAIN www.gleich.dev
COPY --from=downloader /gleich.dev/public /public
COPY build/nginx.conf.tmpl /etc/nginx/nginx.conf.tmpl
COPY build/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx"]
