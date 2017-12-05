# Frequently Asked Questions

This is a collection of questions that might be useful for your specific use case. Feel free to direct any additional question to the maintainer of httpd-exporter.

## Doesn't grok-exporter project provide exactly the same as what httpd-exporter offers?
Yes and No. Yes in a sense that it is already very mature in dealing with log file scraping, parsing log lines and constructing labels and metrics. Unfortunately, grok-exporter can only handle a single log file in a process and has no auto-detection implemented. Using grok-exporter will require you to 

* Install a side car to each HTTP server in your Docker environment,
* Have all logfiles being kept and rotated in the HTTP server container itself - which in turn requires you to install yet another side car just to collect your log files with fluentd or alike.
* Finally, having this in place, you will have many more containers just to control your infrastructure and applications.

httpd-exporter avoids this by having a single process that runs on your machine. This process is able to collect all container log files (and dismiss old ones) and still  does not interfere with your logging infrastructure.

The need for httpd-exporter might go away once - as announced - grok-exporter will be integrated into Prometheus. However, this has not yet happened.

## What are "Dead Labels" and why are they required?
In a typical Docker or Kubernetes environment, containers come and go. And so do their log files. Leaving the metrics for these containers in the exporter would eventually blow up the system as not a single value will ever be deleted. However, deleting counters and values of very old containers will immediately affect your queries that compute sums of these metrics. These totals will decrease. As this wouldn't be exactly a problem in occasional failure situations, it will when you have regular jobs running in temporary containers. The sum of new errors and error counts removed (by expiration) can end up at 0 errors for any given time period. Your monitoring system would not detect anymore that something serious is happening. Therefore, you can move these old values to dead counters. They appear in your metrics with label `deadCounter` to be set to `true`.

## Why is httpd-exporter running as root?
If you have a standalone (outside Docker) installation running then there is no issue having httpd-exporter running with a different user - as long this user can read your log files and write the metrics file. However, all container logs in a Docker environment are readable for root users only (!) and there is no way to mount these log files to the exporter's container as any other user or even just readable. So up-to-now we have to live with this awkward situation. httpd-exporter itself is not required to run as root but the Docker environment currently forces it to do so.


