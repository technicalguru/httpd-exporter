# httpd-exporter
[Prometheus](https://prometheus.io/) Metrics exporter for HTTP daemons (Apache, nginx, ...) based on 
access log file scraping.

# Description
httpd-exporter was written because there were no [Prometheus exporters](https://prometheus.io/docs/instrumenting/exporters/)
that were able to expose information from arbitrary HTTPD log files **and** able to handle multiple logfiles 
within the same instance **and** able to discover these log files automatically while running.

This is especially required when a [Kubernetes](https://kubernetes.io/) cluster or other major [Docker](https://docker.io/) 
installations exist in production. httpd-exporter will provide an insight into the health of single HTTPD 
instances (aka microservices).

# Status
httpd-exporter is in Beta phase. It is running stable in a commercial [Kubernetes](https://kubernetes.io/)
environment. However, it cannot be regarded as mature because the project was initiated for and tested in that 
very specific environment only.

# Installing
## Prerequisites
htppd-exporter is written in Perl. The following prerequisites apply:

* Perl V5.22 or higher (available at `/usr/bin/perl`)
* Perl module [JSON](http://search.cpan.org/perldoc?JSON)
* Perl module [JSON::XS](http://search.cpan.org/~mlehmann/JSON-XS-3.04/XS.pm)
* Perl module [FindBin](https://perldoc.perl.org/FindBin.html)
* Perl module [Cwd](https://perldoc.perl.org/Cwd.html)

Most of these modules shall be already installed with a default Perl installation. Please follow the links above if this is not the case.

## Downloading
Install httpd-exporter by cloning the Git repository:

> `git clone https://github.com/technicalguru/httpd-exporter`

## Testing
Test your installation by invoking:

> `<path-to-installation>/exporterd.pl --test`

A successful test will not produce any output.

# Configuration
httpd-exporter requires a configuration file describing the log files to scrape and the metrics to be produced. A default configuration file
is part of the installation ([exporter.conf](exporter.conf)) which you should install in directory `/etc/httpd-exporter`. Edit the file then to reflect
your installation. 

See the [Configuration](CONFIGURATION.md) page for more details.

# Running
## Invoking the httpd-exporter
The following command invokes the httpd-exporter:

> `<path-to-installation>/exporterd.pl`

The httpd-exporter will try to find your configuration file in the following order:

1. The path to the file was given as argument to the script (`exporterd.pl exporter.conf`).
1. The path to the file is passed by environment variable `HTTPD_EXPORTER_CONFIG_FILE`.
1. Default location is assumed: `/etc/httpd-exporter/exporter.conf`.

httpd-exporter will fail to start when the file was not found or is not readable.

## Exposing metrics
Please notice that you will need an additional HTTPD product (Apache, nginx, ...) that needs to serve
the metrics file produced by the httpd-exporter at the following URL:

> http://&lt;your-host-name&gt;:9386/metrics

## Linking Prometheus to metrics
Prometheus requires the following configuration to scrape the metrics:

TBD

## Docker image
There is a [Docker](https://docker.io/) image available:

> [https://hub.docker.com/r/technicalguru/httpd-exporter/](https://hub.docker.com/r/technicalguru/httpd-exporter/)

The [Kubernetes](https://kubernetes.io/) YAML description for a DaemonSet is available [here](httpd-exporter.yaml).

# Contribution

TBD

# Further Readings

* [Configuration](CONFIGURATION.md)
* [DockerHub Image](https://hub.docker.com/r/technicalguru/httpd-exporter/)


