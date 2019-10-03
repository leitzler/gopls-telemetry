#!/bin/sh
touch /tmp/prom.log /tmp/jaeger.log /tmp/ocagent.log /tmp/grafana.log

/bin/prometheus > /tmp/prom.log 2>&1 &
/go/bin/all-in-one-linux --sampling.strategies-file=/etc/jaeger/sampling_strategies.json > /tmp/jaeger.log 2>&1 &
/bin/ocagent --config ocagent.yml > /tmp/ocagent.log 2>&1 &
/grafana.sh > /tmp/grafana.log 2>&1 &

tail -f /tmp/prom.log | sed 's/^/prom.log: /' &
tail -f /tmp/jaeger.log | sed 's/^/jaeger.log: /' &
tail -f /tmp/ocagent.log | sed 's/^/ocagent.log: /' &
tail -f /tmp/grafana.log | sed 's/^/grafana.log: /'