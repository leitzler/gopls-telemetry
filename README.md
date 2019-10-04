# Telemetry bundle container for gopls

The Go language server [gopls](https://github.com/golang/tools/blob/master/gopls/doc/user.md) supports writing telemetry to an Open Census agent.

This docker image acts as a all-in-one image when you would like to access metrics & traces without going through the installation and setup of ocagent, jaeger, prometheus, etc. It is intended to be used during development for debugging.

## Getting started

The easiest way to get started is to run the image with your host network exposed to the container. That way all services will be accessible directly on localhost.

```bash
$ docker run --network=host -it --rm leitzler/gopls-telemetry 
```

If you rather prefer to specify specific ports, all services inside the container runs on their default port, e.g.:
* ocagent - 55678
* jaeger ui - 16686
* grafana - 3000
* prometheus - 9090

Start gopls with `-ocagent`, e.g.:
```bash
$ gopls -ocagent=http://127.0.0.1:55678
```

## Traces
Traces are available from Jaeger, at `http://localhost:16686`.

## Metrics
There are currently no metrics in `gopls`, but they will be available in grafana, at `http://localhost:3000`. Username and password is set to admin/password, and there is a pre-defined datasource already pointing at prometheus.


