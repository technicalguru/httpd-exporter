#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Cwd            qw( abs_path );
use File::Basename qw( dirname );
use JSON;
use JSON::XS;
use Sys::Hostname;
use Socket;

# Get our path
use lib "$FindBin::RealBin";
use lib "$FindBin::RealBin/modules";
use lib "$FindBin::RealBin/test";

# Load our modules
use ApExportConfiguration;
use ApExportCollector;
use ApExportMetrics;
use ApExportLogfile;
use ApExportMatcher;
use ApExportTestSuite;

# Special argument --test - perform system tests to check whether
# the environment fits our requirements
if (exists($ARGV[0]) && ($ARGV[0] eq '--test')) {
	exit performTests();
}
# Special argument --test-loop - run idle loop 
# (useful in containers to check reason for errors)
if (exists($ARGV[0]) && ($ARGV[0] eq '--test-loop')) {
	while (1) {
		sleep 10000;
	}
}

# Get the config file from cmd argument
my $configFile = shift;

# Fallback: Environment variable
if (!$configFile) {
	$configFile = $ENV{'APEXPORT_CONFIG_FILE'};
}

# Fallback: Default location
if (!$configFile) {
	$configFile = '/etc/httpd-exporter/exporter.conf';
}

# Check existance of config file
if (!-f $configFile) {
	die "Cannot find configuration: $configFile\n";
}

# Now read the configuration
my $CONFIG = new ApExportConfiguration($configFile);

# Read an existing metrics file
my $COLLECTOR = new ApExportCollector($CONFIG->getGeneral('metricsFile'));

# Initialize the logfile hash
my $LOGFILES = {};

# Initialize the matcher
my $MATCHER = new ApExportMatcher($CONFIG->getLogFormats());

# Compute global vars
my $GLOBALS = {
	'HOSTIP'   => inet_ntoa((gethostbyname(hostname))[4]),
	'HOSTNAME' => hostname(),
};

# Create two metrics
$COLLECTOR->getOrCreateMetrics('http_requests_total', 'Counter', 'Counts the requests that were logged by HTTP daemon');
$COLLECTOR->getOrCreateMetrics('http_sent_bytes', 'Counter', 'Number of bytes transferred as logged by HTTP daemon');

# Enter the daemon loop
while (1) {
	my ($key);

	# check all existing file handles/log files whether they are still exist
	foreach $key (keys(%{$LOGFILES})) {
		my $logfile = $LOGFILES->{$key};
		# remove them from watch list if require
		if (!$logfile->isHealthy()) {
			$logfile->close();
			delete($LOGFILES->{$key});
		}
	}

	# Re-scan locations for new log files and add them
	foreach $key ($CONFIG->getLocations()) {
		my @LOCATIONS = glob($key);
		my $locationConfig = $CONFIG->getLocation($key);
		my $location;
		foreach $location (@LOCATIONS) {
			# Create logfile location if not yet present
			if (!exists($LOGFILES->{$location})) {
				my $logfile = new ApExportLogfile($location, $locationConfig);
				if ($logfile->isHealthy()) {
					$LOGFILES->{$location} = $logfile;
				} else {
					print STDERR "Cannot open $location\n";
				}
			}
		}
	}

	# loop on all log files
	my $changed = 0;
	if (scalar(keys(%{$LOGFILES}))) {
		foreach $key (keys(%{$LOGFILES})) {
			my $logfile = $LOGFILES->{$key};
			my @LINES   = $logfile->getNewLines();

			# process the log entries
			my $line;
			foreach $line (@LINES) {
				my $vars = $MATCHER->matchLog($line->{log});
				if (defined($vars)) {
					# add global values
					my $gkey;
					foreach $gkey (keys(%{$GLOBALS})) {
						$vars->{$gkey} = $GLOBALS->{$gkey};
					}
					# compute base labels
					my $labels = $logfile->computeLabels($vars);
					# Add global labels
					my $label;
					foreach $label (split(',', $CONFIG->getGeneral('addLabels'))) {
						if (exists($vars->{$label})) {
							$labels->{$label} = $vars->{$label};
						} else {
							$labels->{$label} = '';
						}
					}
					# Add specific group labels
					my $statusValue = $CONFIG->getGeneral('addStatusGroupLabel');
					if (defined($statusValue)) {
						if (exists($vars->{$statusValue})) {
							$labels->{status} = getStatusGroup($vars->{$statusValue});
						} else {
							$labels->{status} = 'UNKNOWN';
						}
					}
					# Add metric bytes_transferred_total
					my $sentBytesVar = $CONFIG->getGeneral('collectBytesTransferred');
					if (defined($sentBytesVar) && exists($vars->{$sentBytesVar})) {
						my $metrics = $COLLECTOR->getMetrics('http_sent_bytes');
						$metrics->add($vars->{$sentBytesVar}, $labels);
						$changed = 1;
					}
					
					# Increase metric requests_total
					{
						my $metrics = $COLLECTOR->getMetrics('http_requests_total');
						$metrics->inc($labels);
						$changed = 1;
					}
				}
			}
		}
	}

	# Save the metrics
	$COLLECTOR->save('text/plain') if $changed;

	# sleep a few seconds to minimize system load
	sleep(5);
}

# We shall never get here
exit 0;

sub getStatusGroup {
	my $status = shift;

	if (($status < 100) || ($status >= 1000)) {
		return 'other';
	}
	my $statusGroup = int ($status / 100);
	return $statusGroup.'xx';
}

sub performTests {
	my $testSuite = new ApExportTestSuite("$FindBin::RealBin/test");
	my $rc = $testSuite->execute();
	return $rc;
}

