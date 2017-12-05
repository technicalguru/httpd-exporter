## httpd-exporter
[Prometheus](https://prometheus.io/) Metrics exporter for HTTP daemons (Apache, nginx, ...) based on access log file scraping.

# Supported Tags
* `current` ([Dockerfile](https://github.com/technicalguru/httpd-exporter/build/Dockerfile)) - latest (unstable) development image

# Status
httpd-exporter is in Beta phase. It is running stable in a commercial [Kubernetes](https://kubernetes.io/) environment. However, it cannot be regarded as mature because the project was initiated for and tested in that very specific environment only.

# How to use this image

* **Configuration File**
httpd-exporter requires a configuration file describing the log files to scrape and the metrics to be produced. You need to copy/mount your configuration in directory `/etc/httpd-exporter` or provide the location via environment variable `HTTPD_EXPORTER_CONFIG_FILE`. See the [Configuration](https://github.com/technicalguru/httpd-exporter/help/CONFIGURATION.md) page for more details.

* **HTTPD Log Files**
httpd-exporter scrapes log files. The configuration file must list all the locations where these log files are available. Make sure you mount your log files to be analyzed into the container at the right place. Please notice that - due to a Docker limitation - httpd-exporter requires to run as user root in order to have access to Docker container log files.

* **Metrics File**
httpd-exporter does not serve the metrics itself but requires an additional HTTP server, such as nginx, Apache, Tomcat, et al. The metrics are written to the location as given in the configuration file, preferrably at `/var/www/html/metrics`. Therefore, it is required that httpd-exporter has this directory mounted and it is writable. The HTTP server must expose the metrics at this URL: http://&lt;your-server-name&gt;:9386/metrics. This is the reserved port for httpd-exporter.

# Linking Prometheus to metrics
Prometheus requires the following configuration to scrape the metrics:

TBD

# Kubernetes Setup
The [Kubernetes](https://kubernetes.io/) YAML description for a DaemonSet is available [here](https://github.com/technicalguru/httpd-exporter/contrib/kubernetes/exporter.yaml). It will automatically configure httpd-exporter for your cluster and provide an nginx container for serving the metrics. Install it via:

```
kubectl apply -f https://github.com/technicalguru/httpd-exporter/contrib/kubernetes/exporter.yaml
```

# Metrics Exposed
The httpd-exporter exposes the following metrics:

```
 # TYPE http_requests_total Counter
 # HELP http_requests_total Counts the requests that were logged by HTTP daemon
 http_requests_total{"instance.hostname":"example.com","instance.ip":"10.0.0.10","method":"GET","status":"2xx"} 5432 1512397393
 http_requests_total{"instance.hostname":"example.com","instance.ip":"10.0.0.10","method":"GET","status":"4xx"} 32 1512397393
 http_requests_total{"instance.hostname":"example.com","instance.ip":"10.0.0.10","method":"GET","status":"5xx"} 5 1512397393

 # TYPE http_sent_bytes Counter
 # HELP http_sent_bytes Number of bytes transferred as logged by HTTP daemon
 http_sent_bytes{"instance.hostname":"example.com","instance.ip":"10.0.0.10","method":"GET","status":"2xx"} 235432 1512397393
 http_sent_bytes{"instance.hostname":"example.com","instance.ip":"10.0.0.10","method":"GET","status":"4xx"} 3782 1512397393
 http_sent_bytes{"instance.hostname":"example.com","instance.ip":"10.0.0.10","method":"GET","status":"5xx"} 4375 1512397393
```

Metrics are attributed with appropriate labels as defined by the [configuration file](https://github.com/technicalguru/httpd-exporter/help/CONFIGURATION.md). You might 
require the following Prometheus expressions to query your HTTPD status:

```
delta(http_requests_total{status!="2xx"}[5m])  - returns number of requests in the last 5 minutes for each label combination that were not successful
sum(delta(http_requests_total{status!="2xx"}[5m])) - returns the total count of requests in the last 5 minutes that failed
```

# Further Readings

* [Documentation](https://github.com/technicalguru/httpd-exporter/README.md)
* [Configuration](https://github.com/technicalguru/httpd-exporter/help/CONFIGURATION.md)
* [FAQ](https://github.com/technicalguru/httpd-exporter/help/FAQ.md)


