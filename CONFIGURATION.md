# Configuration

```
[General]
metricsFile=/var/www/html/metrics

[LogFormats]
%{HOSTNAME:hostname}(:%{INT:port})? %{IP:clientip} %{NOTSPACE:rlogname} %{NOTSPACE:user} \[%{HTTPDATE:timestamp}\] "%{REQUEST_LINE}" %{INT:status} %{INT:bytes_sent} (%{QS:
referrer}|-) (%{QS:agent}|-)
%{IP:clientip} %{NOTSPACE:rlogname} %{NOTSPACE:user} \[%{HTTPDATE:timestamp}\] "%{REQUEST_LINE}" %{INT:status} %{INT:bytes_sent} (%{QS:referrer}|-) (%{QS:agent}|-)
%{IP:clientip} %{NOTSPACE:rlogname} %{NOTSPACE:user} \[%{HTTPDATE:timestamp}\] "%{REQUEST_LINE}" %{INT:status} %{INT:bytes_sent}

[/var/log/apache2/access.log]
type=httpd
labels={ "instance" : "$HOST_IP", "hostname" : "$HOSTNAME" }

[/var/lib/docker/containers/*]
type=kubernetes
labels={ "instance" : "$HOSTIP", "HOSTNAME" : "$HOSTNAME", "container.name" : "$CONTAINER_NAME" }

#[/var/lib/docker/containers/*]
#type=docker
#labels={ "instance" : "$HOST_IP", "hostname" : "$HOSTNAME", "container.name" : "$CONTAINER_NAME" }
```
