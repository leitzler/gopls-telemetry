# build stages
FROM jaegertracing/all-in-one:1.14.0 as jaeger
FROM prom/prometheus:v2.12.0 as prometheus
FROM golang:1.13 as ocagent-build
RUN git clone https://github.com/census-instrumentation/opencensus-service && \
    cd opencensus-service && \
    git checkout fb16513301ba831e33020eccb21198292402b9d3 && \
    go mod edit -require=github.com/prometheus/prometheus@master && \
    make agent
FROM grafana/grafana:6.4.1 as grafana

# build
FROM alpine:3.10.2
RUN apk add --no-cache tini

# jaeger
COPY --from=jaeger /go/bin/all-in-one-linux /go/bin/all-in-one-linux
COPY --from=jaeger /etc/jaeger/sampling_strategies.json /etc/jaeger/sampling_strategies.json
# prometheus
COPY --from=prometheus /bin/prometheus /bin/prometheus
# ocagent
COPY --from=ocagent-build /go/opencensus-service/bin/ocagent_linux /bin/ocagent
# grafana
ENV PATH=/usr/share/grafana/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
    GF_PATHS_DATA="/var/lib/grafana" \
    GF_PATHS_HOME="/usr/share/grafana" \
    GF_PATHS_LOGS="/var/log/grafana" \
    GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
    GF_PATHS_PROVISIONING="/etc/grafana/provisioning"

WORKDIR $GF_PATHS_HOME

RUN apk update && apk upgrade && \
    apk add --update --no-cache ca-certificates libc6-compat ca-certificates && \
    rm -rf /var/cache/apk/*

COPY --from=grafana $GF_PATHS_HOME $GF_PATHS_HOME
COPY --from=grafana /run.sh /grafana.sh

RUN mkdir -p "$GF_PATHS_HOME/.aws" && \
    mkdir -p "$GF_PATHS_PROVISIONING/datasources" \
             "$GF_PATHS_PROVISIONING/dashboards" \
             "$GF_PATHS_PROVISIONING/notifiers" \
             "$GF_PATHS_LOGS" \
             "$GF_PATHS_PLUGINS" \
             "$GF_PATHS_DATA" && \
    cp "$GF_PATHS_HOME/conf/sample.ini" "$GF_PATHS_CONFIG" && \
    cp "$GF_PATHS_HOME/conf/ldap.toml" /etc/grafana/ldap.toml && \
    chmod 777 "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" && \
    chmod -R 777 $GF_PATHS_HOME /grafana.sh && \
    sed -i 's/bash/sh/g' /grafana.sh

# configs
COPY prometheus.yml prometheus.yml
COPY ocagent.yml ocagent.yml
COPY grafana.ini $GF_PATHS_CONFIG
COPY grafana-datasource.yml $GF_PATHS_PROVISIONING/datasources/prom.yml

# entrypoint
COPY run.sh run.sh

# grafana
EXPOSE 3000
# jaeger ui
EXPOSE 14268
# prometheus
EXPOSE 9090
# ocagent
EXPOSE 55678

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["./run.sh"]
