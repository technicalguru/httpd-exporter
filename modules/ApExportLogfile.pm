package ApExportLogfile;
use strict;
use warnings;
use ApExportMetrics;
use Fcntl;
use JSON;
use JSON::XS;


# Constructor.
# Arguments: $path   - location of log file
#            $config - configuration of log file
sub new {
	my $class = shift;
	my $self  = { 
		'path'   => shift,
		'config' => shift,
		'labels' => {},
		'size'   => 0,
	};
	my $rc = bless $self, $class;

	# Compute the log file
	if ($self->{config}->{type} eq 'httpd') {
		$self->{logfile} = $self->{path};
	} elsif ($self->{config}->{type} eq 'docker') {
		my $name = $self->{path};
		$name =~ s/^.*\///g;
		$self->{logfile} = $self->{path}.'/'.$name.'-json.log';
		$rc->computeDockerLabels();
	} elsif ($self->{config}->{type} eq 'kubernetes') {
		my $name = $self->{path};
		$name =~ s/^.*\///g;
		$self->{logfile} = $self->{path}.'/'.$name.'-json.log';
		$rc->computeKubernetesLabels();
	}

	# Save the current state
	$self->{size}   = $rc->getSize();
	return $rc;
}

# Open the log file and set position at end of file
# Arguments: (none)
sub getSize {
	my $self = shift;
	my @RC = stat($self->{logfile});
	return $RC[7];
}

# Closes the file for reading.
# Arguments: (none)
sub close {
	my $self = shift;
}

# Returns whether the file handle is healthy
# Arguments: (none)
sub isHealthy {
	my $self = shift;
	my $rc   = 1;

	# File must still exist
	$rc = 0 if !-f $self->{logfile};

	return $rc;
}

# Reads lines from the file handle
sub getNewLines {
	my $self = shift;
	my $curSize = $self->getSize();
	my @RC = ();
	my @T  = gmtime(time);
	my $time = sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $T[5]+1900, $T[4]+1, $T[3], $T[2], $T[1], $T[0]);

	# When size of file changed
	if ($self->{size} != $curSize) {
		# Open the file
		my $fh;
		if (open($fh, '<'.$self->{logfile})) {
			# Decide where to position the pointer
			my $pos = 0;
			if ($curSize > $self->{size}) {
				$pos = $self->{size};
			}
			seek($fh, $pos, 0);
			# Now read until the end
			while (<$fh>) {
				chomp;
				my $line = $_;
				if ($self->{config}->{type} eq 'httpd') {
					# We need to create log entry
					$line = {
						'log'  => $line,
						'time' => $time,
						'file' => $self->{logfile},
					};
				} else {
					$line = from_json($line);
				}
				push(@RC, $line);
			}
			CORE::close($fh);
			$self->{size} = $curSize;
		} else {
			# this went wrong
		}
	}

	return (@RC);
}

# Compute the labels defined for this location and logfile.
# Arguments: $vars - variables as matched from log (plus additional global vars)
sub computeLabels {
	my $self = shift;
	my $vars = shift;
	my $rc   = {};

	# Enrich variables with type-specific labels (docker/kubernetes)
	$self->addLogfileLabelVars($vars);

	# Replace variables now
	if (exists($self->{config}->{labels})) {
		my $labelDef = ApExportMetrics::from_label_string($self->{config}->{labels});
		my $key;
		foreach $key (keys(%{$labelDef})) {
			my $valueDef = $labelDef->{$key};
			my $v = $valueDef;
			while ($valueDef =~ /\$\{([^\}]+)\}/gi) {
				my $n     = $1;
				if (exists($vars->{$n})) {
					my $value = $vars->{$n};
					$v =~ s/\$\{$n\}/$value/g;
				}
			}
			$rc->{$key} = $v;
		}
	}

	# Add logfile specific labels
	$self->addLogfileLabels($rc);
	return $rc;
}

# Adds logfile specific variables to a hashref.
# These variables can be used additionally (but it is senseless as they are already added as standard labels}.
# Arguments: $vars - the hashref to be completed
sub addLogfileLabelVars {
	my $self = shift;
	my $vars = shift;

	my $key;
	foreach $key (keys(%{$self->{labels}})) {
		$vars->{$key} = $self->{labels}->{$key};
	}
	return $vars;
}

# Adds logfile specific labels to a hashref.
# Arguments: $labels - the hashref to be completed
sub addLogfileLabels {
	my $self   = shift;
	my $labels = shift;

	my $key;
	foreach $key (keys(%{$self->{labels}})) {
		$labels->{$key} = $self->{labels}->{$key};
	}
	return $labels;
}

# Computes all labels for this plain log file.
# Currently nothing to do
# Arguments: (none)
sub computeFileLabels {
	my $self = shift;
}

# Returns the container config file (JSON-encoded config.v2.json file).
# Arguments: (none)
# Returns: hashref of config file
sub _getContainerConfig {
	my $self = shift;
	my $rc = {};

	if (open(FIN, '<'.$self->{path}.'/config.v2.json')) {
		my $json = <FIN>;
		CORE::close(FIN);
		return from_json($json);
	}

	return $rc;
}

# Computes all logfile specific labels in a docker environment.
# These labels are present in types 'docker' and 'kubernetes'.
# Arguments: $config - the config hashref
# Returns: (none)
sub computeStandardDockerLabels {
	my $self   = shift;
	my $config = shift;

	$self->{labels}->{'docker.container.name'}     = $config->{Name};
#	$self->{labels}->{'docker.state.running'}      = $config->{State}->{Running};
#	$self->{labels}->{'docker.state.paused'}       = $config->{State}->{Paused};
#	$self->{labels}->{'docker.state.dead'}         = $config->{State}->{Dead};
	$self->{labels}->{'docker.container.hostname'} = $config->{Config}->{Hostname};

	# Add all user labels
	if (exists($config->{Config}->{Labels})) {
		my $key;
		foreach $key (keys(%{$config->{Config}->{Labels}})) {
			if (($key !~ /^annotation\./) && ($key !~ /^io\.kubernetes/) && ($key !~ /^com\.docker/)) {
				$self->{labels}->{$key} = $config->{Config}->{Labels}->{$key};
			}
		}
	}
}

# Computes all logfile specific labels for a docker environment.
# Retrieves basically the same as #_getContainerConfig().
# Arguments: $config - the config hashref
# Returns: (none)
sub computeDockerLabels {
	my $self = shift;

	my $config = $self->_getContainerConfig();
	$self->computeStandardDockerLabels($config);
}

# Computes all logfile specific labels for a Kubernetes environment.
# Retrieves #_getContainerConfig() and additional K8s labels.
# Arguments: $config - the config hashref
# Returns: (none)
sub computeKubernetesLabels {
	my $self = shift;

	my $config = $self->_getContainerConfig();

	# Add Docker standard labels
	$self->computeStandardDockerLabels($config);

	# Kubernetes specific labels
	$self->{labels}->{'kubernetes.container.name'} = $config->{Config}->{Labels}->{'io.kubernetes.container.name'};
	$self->{labels}->{'kubernetes.container.type'} = $config->{Config}->{Labels}->{'io.kubernetes.docker.type'};
	$self->{labels}->{'kubernetes.namespace.name'} = $config->{Config}->{Labels}->{'io.kubernetes.pod.namespace'};
	$self->{labels}->{'kubernetes.pod.name'}       = $config->{Config}->{Labels}->{'io.kubernetes.pod.name'};
	$self->{labels}->{'kubernetes.pod.uid'}        = $config->{Config}->{Labels}->{'io.kubernetes.pod.uid'};
}

1;
