# Configuration

## The configuration file
A configuration file consists of at least three sections:

1. A [General](#user-content-general-section) section describing the metrics
1. A [LogFormats](#user-content-logformats-section) section describing how a HTTPD log line must look like for scraping
1. One or several [Location](#user-content-location-sections) sections describing each group of log files to scrape

## Example configuration

```
[General]
metricsFile=/var/www/html/metrics
addLabels=method
addStatusGroupLabel=status
collectBytesTransferred=bytes_sent
retentionSeconds=3600
deadLabels=method,status

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
labels={ "instance.ip" : "${HOSTIP}", "instance.hostname" : "${HOSTNAME}" }

[/var/lib/docker/containers/*]
type=kubernetes
labels={ "instance.ip" : "${HOSTIP}", "instance.hostname" : "${HOSTNAME}" }
```

## General Section
This is a `key=value` section. The following values can be configured:

Key|Value|Required|Default|Description
---|-----|--------|-------|-----------
metricsFile|&lt;path&gt;|YES|-|The path to the file where metrics will be stored and served by your HTTPD product. Usually `/var/www/html/metrics`.
addLabels|&lt;name-of-variable&gt;|NO|-|Add a label based on the variable of the given name(s) - comma-separated list.
addStatusGroupLabel|&lt;name-of-variable&gt;|NO|-|Group metrics by the HTTP status code which is given by the variable of the given name.
collectBytesTransferred|&lt;name-of-variable&gt;|NO|-|Add a http_sent_bytes metrics and add up the values of the variable of the given name.
retentionSeconds|&lt;seconds&gt;|NO|3600|Regard metrics that were not updated within that period of time to be expired (dead) and remove them.
deadLabels|&lt;list-of-labels&gt;|NO|-|Use these labels for dead metrics. Expired metrics will be added up to the respective dead label value.

## LogFormats Section
This is a list section. Each line gives a description of log line that can occur in your installation. These are basically regular Perl expressions
that are inspired by [grok-exporter](https://github.com/fstab/grok_exporter) syntax. Use the `%{TYPE:name}` 
syntax to match certain default parts in a log line. "name" will define
a variable that is made available and holds the value of the matched expression. The following types
are available:

Type|Description|Example
----|-----------|-------
HOSTNAME|Matches a hostname or IP address|`%{HOSTNAME:virtualHost}`
HTTPDATE|Matches a standard HTTP date, e.g. `01/Dec/2017:15:20:04 +0100`. The match will set four variables: method, path, protocol and protocolVersion|`%{HTTPDATE:requestTime}`
INT|Matches an unsigned integer|`%{INT:status}`
IP|Matches an IP address (v4 or v6)|`%{IP:clientIP}`
NOTSPACE|Matches any string not containing any whitespace character|`%{NOTSPACE:user}`
QS|Matches a quoted string, e.g. `"This is a \"quoted String\""`|`%{QS:agent}`

You can use standard Perl regular expressions in the `LogFormats` section. Use the following sytax in order to define a variable "myVar":

> `(?<myVar>...)`

Please notice that `>` and `<` are literals that must be present.

## Location Sections
This is a `key=value` section. The section title is the (shell-alike) regular expression for matching log files or container directories.
The following values can be configured:

Key|Value|Required|Default|Description
---|-----|--------|-------|-----------
type|`httpd` or `docker` or `kubernetes`|YES|-|Describing the type of the log file(s): Please notice that `docker` and `kubernetes` sections must match directories (usually at `/var/lib/docker/containers`, whereas `httpd` must match single log files.
labels|JSON string|NO|-|JSON string of additional labels to be produced in metrics for this log file(s)


