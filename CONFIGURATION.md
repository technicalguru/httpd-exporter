# Configuration

## The configuration file
A configuration file consists of at least three sections:

1. A [General](#General) section describing the metrics
1. A [LogFormats](#LogFormats) section describing how a HTTPD log line must look like for scraping
1. One or several [Location](#Location) sections describing each group of log files to scrape

## Example configuration

```
[General]
metricsFile=/var/www/html/metrics

[LogFormats]
# Format used mostly in reverse proxy installations
%{HOSTNAME:hostname}(:%{INT:port})? %{IP:clientip} %{NOTSPACE:rlogname} %{NOTSPACE:user} \[%{HTTPDATE:timestamp}\] "%{REQUEST_LINE}" %{INT:status} %{INT:bytes_sent} (%{QS:
referrer}|-) (%{QS:agent}|-)
# Default Apache log format
%{IP:clientip} %{NOTSPACE:rlogname} %{NOTSPACE:user} \[%{HTTPDATE:timestamp}\] "%{REQUEST_LINE}" %{INT:status} %{INT:bytes_sent} (%{QS:referrer}|-) (%{QS:agent}|-)
# A simple log format
%{IP:clientip} %{NOTSPACE:rlogname} %{NOTSPACE:user} \[%{HTTPDATE:timestamp}\] "%{REQUEST_LINE}" %{INT:status} %{INT:bytes_sent}

[/var/log/apache2/access.log]
type=httpd
labels={ "instance" : "$HOST_IP", "hostname" : "$HOSTNAME" }

[/var/lib/docker/containers/*]
type=kubernetes
labels={ "instance" : "$HOSTIP", "HOSTNAME" : "$HOSTNAME", "container.name" : "$CONTAINER_NAME" }
```

## General Section

TBD

## LogFormats Section

TBD

## Location Sections

