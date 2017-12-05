package ApExporter;
use strict;
use warnings;
use FindBin;
use Cwd            qw( abs_path );
use File::Basename qw( dirname );
use JSON;
use JSON::XS;
use Sys::Hostname;
use Socket;

# Load our modules
use ApExportConfiguration;
use ApExportCollector;
use ApExportMetrics;
use ApExportLogfile;
use ApExportMatcher;
use ApExportTestSuite;

# Constructor.
# Arguments: $configFile - location of configuration file
sub new {
	my $class = shift;
	my $configFile = shift;
	my $self  = {
		'config' => new ApExportConfiguration($configFile),
		'globalVars' => {
			'HOSTIP'   => inet_ntoa((gethostbyname(hostname))[4]),
			'HOSTNAME' => hostname(),
		},
	};
	$self->{collector} = new ApExportCollector($self->{config}->getGeneral('metricsFile'));
	$self->{matcher}   = new ApExportMatcher($self->{config}->getLogFormats());

	my $rc = bless $self, $class;
	# Create two metrics and tell them the dead labels
	my @METRICS = ();
	push(@METRICS, $rc->{collector}->getOrCreateMetrics('http_requests_total', 'Counter', 'Counts the requests that were logged by HTTP daemon'));
	push(@METRICS, $rc->{collector}->getOrCreateMetrics('http_sent_bytes', 'Counter', 'Number of bytes transferred as logged by HTTP daemon'));
	my $label;
	foreach $label (split(@{$self->{config}->getGeneral('deadLabels')})) {
		my $m;
		foreach $m (@METRICS) {
			$m->addDeadLabel($label);
			$m->setRetentionSeconds($self->{config}->getGeneral('retentionSeconds'));
		}
	}
	return $rc;
}

# Runs the daemon.
# Arguments: (none)
sub run {
	my $self = shift;

	# Initialize the logfile hash
	my $logFiles = {};

	# Enter the daemon loop
	while (1) {
		# Cleanup
		$self->cleanOldFiles($logFiles);

		# Add new files
		$self->findNewFiles($logFiles);

		# Whether we need to save the metrics again
		my $changed = 0;

		# loop on all log files
		if (scalar(keys(%{$logFiles}))) {
			my $key;
			foreach $key (keys(%{$logFiles})) {
				my $logfile = $logFiles->{$key};
				my @LINES   = $logfile->getNewLines();
	
				# process the log entries
				$changed += $self->processLog($logfile, \@LINES);

			}
		}
	
		# Save the metrics
		$self->{collector}->save('text/plain') if $changed;
	
		# sleep a few seconds to minimize system load
		sleep(5);
	}
}

# Loop over given log files and cleanup any un-healthy entries.
# Arguments: $logFiles - hashref of logfiles
sub cleanOldFiles {
	my $self     = shift;
	my $logFiles = shift;
	my $key;

	# check all existing file handles/log files whether they are still exist
	foreach $key (keys(%{$logFiles})) {
		my $logfile = $logFiles->{$key};
		# remove them from watch list if require
		if (!$logfile->isHealthy()) {
			$logfile->close();
			delete($logFiles->{$key});
		}
	}

	return $logFiles;
}

# Process log entries for a given log file
# Arguments: $logfile - the logfile object
#            $lines   - arrayref to log hashrefs
sub processLog {
	my $self    = shift;
	my $logfile = shift;
	my $lines   = shift;
	my $rc      = 0;

	my $line;
	foreach $line (@{$lines}) {
		my $vars = $self->{matcher}->matchLog($line->{log});
		if (defined($vars)) {
			$self->addGlobalVars($vars);

			# compute base labels
			my $labels = $logfile->computeLabels($vars);

			# Add global labels
			$self->addGlobalLabels($labels, $vars);

			# Add specific group labels
			$self->addGroupedLabels($labels, $vars);

			# Collect metrics
			$rc += $self->collectBytesSentMetrics($labels, $vars);
			$rc += $self->collectRequestsMetrics($labels, $vars);

		}
	}
	return $rc;
}

# Adds the global variables to the given hashref.
# Arguments: $vars - the hashref to be amended
sub addGlobalVars {
	my $self = shift;
	my $vars = shift;

	# add global values
	my $key;
	foreach $key (keys(%{$self->{globalVars}})) {
		$vars->{$key} = $self->{globalVars}->{$key};
	}

	return $vars;
}

# Amends the label hashref with defined labels from general config.
# Arguments: $labels - hashref to labels to be amended
#            $vars   - variables to be used
sub addGlobalLabels {
	my $self   = shift;
	my $labels = shift;
	my $vars   = shift;

	my $label;
	foreach $label (split(',', $self->{config}->getGeneral('addLabels'))) {
		if (exists($vars->{$label})) {
			$labels->{$label} = $vars->{$label};
		} else {
			$labels->{$label} = '';
		}
	}

	return $labels;
}

# Amends the label hashref with defined grouped labels from general config (only status so far).
# Arguments: $labels - hashref to labels to be amended
#            $vars   - variables to be used
sub addGroupedLabels {
	my $self   = shift;
	my $labels = shift;
	my $vars   = shift;

	my $statusValue = $self->{config}->getGeneral('addStatusGroupLabel');
	if (defined($statusValue)) {
		if (exists($vars->{$statusValue})) {
			$labels->{status} = $self->getStatusGroup($vars->{$statusValue});
		} else {
			$labels->{status} = 'UNKNOWN';
		}
	}
	return $labels;
}

# Scans all locations for new log files appearing
# Arguments: $logFiles - logfile hashref to be amended
sub findNewFiles {
	my $self     = shift;
	my $logFiles = shift;
	my $key;

	# Re-scan locations for new log files and add them
	foreach $key ($self->{config}->getLocations()) {
		my @LOCATIONS = glob($key);
		my $locationConfig = $self->{config}->getLocation($key);
		my $location;
		foreach $location (@LOCATIONS) {
			# Create logfile location if not yet present
			if (!exists($logFiles->{$location})) {
				my $logfile = new ApExportLogfile($location, $locationConfig);
				if ($logfile->isHealthy()) {
					$logFiles->{$location} = $logfile;
				} else {
					print STDERR "Cannot open $location\n";
				}
			}
		}
	}

	return $logFiles;
}

# Amends the metrics for http_sent_bytes if required.
# Arguments: $labels - hashref to labels
#            $vars   - variables to be used
# Returns: >0 when the metrics were amended
sub collectBytesSentMetrics {
	my $self   = shift;
	my $labels = shift;
	my $vars   = shift;
	my $rc     = 0;

	# Add metric bytes_transferred_total
	my $sentBytesVar = $self->{config}->getGeneral('collectBytesTransferred');
	if (defined($sentBytesVar) && exists($vars->{$sentBytesVar})) {
		my $metrics = $self->{collector}->getMetrics('http_sent_bytes');
		$metrics->add($vars->{$sentBytesVar}, $labels);
		$rc = 1;
	}

	return $rc;
}

# Amends the metrics for http_requests_total if required.
# Arguments: $labels - hashref to labels 
#            $vars   - variables to be used
# Returns: >0 when the metrics were amended
sub collectRequestsMetrics {
	my $self   = shift;
	my $labels = shift;
	my $vars   = shift;

	# Increase metric requests_total
	my $metrics = $self->{collector}->getMetrics('http_requests_total');
	$metrics->inc($labels);
	return 1;
}

# Compute the statusGroup label value.
# Will only return 1xx,2xx,3xx...9xx or 'other'.
# Arguments: $status - the HTTP status code
sub getStatusGroup {
	my $self = shift;
	my $status = shift;

	if (($status < 100) || ($status >= 1000)) {
		return 'other';
	}
	my $statusGroup = int ($status / 100);
	return $statusGroup.'xx';
}

# Perform the tests from the test suite
# Arguments: (none)
sub performTests {
	my $self = shift;
	my $testSuite = new ApExportTestSuite("$FindBin::RealBin/test");
	my $rc = $testSuite->execute();
	return $rc;
}

# Perform a dummy loop for test purposes
# Arguments: (none)
sub performDummyLoop {
	my $self = shift;
	while (1) {
		sleep 10000;
	}
}

1;

