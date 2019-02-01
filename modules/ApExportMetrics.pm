package ApExportMetrics;
use strict;
use warnings;
use JSON;
use JSON::XS;

# Constructor.
# Arguments: $name - name of single metric
sub new {
	my $class = shift;
	my $self  = { 
		'name'       => shift,
		'values'     => {},
		'timestamps' => {},
		'deadLabels' => [],
		'enableDeadLabels' => 1,
		'retentionSeconds' => 3600,
	};
	return bless $self, $class;
}

# Sets the help text for this metric
# Arguments: $help - the single line help text
sub setHelp {
	my $self  = shift; 
	my $help  = shift;
	$self->{help} = $help;
}

# Sets the type for this metric
# Arguments: $type - the type
sub setType {
	my $self  = shift; 
	my $type  = shift;
	$self->{type} = $type;
}

# Enables/Disabled dead label usage
# Arguments: $bool - 1/0 to enable/diable
sub setDeadLabelsEnabled {
	my $self  = shift; 
	my $bool  = shift;
	$self->{enableDeadLabels} = $bool;
}

# Adds a label to be used for dead series
# Arguments: $label - label for dead values
sub addDeadLabel {
	my $self  = shift;
	my $label = shift;

	push(@{$self->{deadLabels}}, $label);
}

# Sets the rentention period in seconds.
# The retention period marks the time a certain value will be regarded as
# expired and therefore move to the dead values.
# Arguments: $value - rentention period in seconds
sub setRetentionSeconds {
	my $self  = shift;
	my $value = shift;
	$value = 3600 if !defined($value);
	$self->{retentionSeconds} = $value;
}

# standardizes the labels given for storing in this metric
# Arguments: $in - labels (either hashref or string)
sub standardLabels {
	my $self  = shift; 
	my $in    = shift;

	if ($in) {
		my $labels = ref($in) ? $in : from_label_string($in);
		my @OUT = ();
		my $key;
		foreach $key (sort(keys(%{$labels}))) {
			push(@OUT, $key.'="'.$labels->{$key}.'"');
		}
		if (scalar(@OUT)) {
			return '{'.join(',', @OUT).'}';
		}
	}
	return '';
}

# Gets the value for this metric.
# Arguments: $labels - string-encoded map of labels
sub get {
	my $self   = shift; 
	my $labels = shift;
	my $rc     = 0;
	$labels    = $self->standardLabels($labels);

	if ($labels) {
		if (exists($self->{values}->{$labels})) {
			$rc = $self->{values}->{$labels};
		}
	} else {
		if (exists($self->{value})) {
			$rc = $self->{value};
		}
	}
	return $rc;
}

# Returns a list of all available labels
# Arguments: (none)
sub getLabels {
	my $self = shift; 
	my @RC   = ();

	@RC = keys(%{$self->{values}});
	return (@RC);
}

# Sets the value for this metric
# Arguments: $value     - the value
#            $labels    - string-encoded map of labels
#            $timestamp - timestamp of this value (optional)
sub set {
	my $self      = shift; 
	my $value     = shift;
	my $labels    = shift;
	my $timestamp = shift;
	$labels       = $self->standardLabels($labels);
	$timestamp    = time()*1000 if !defined($timestamp);

	if ($labels) {
		$self->{values}->{$labels}     = $value;
		$self->{timestamps}->{$labels} = $timestamp;
	} else {
		$self->{value}     = $value;
		$self->{timestamp} = $timestamp;
	}
}

# Increases the value for this metric
# Arguments: $labels - string-encoded map of labels
#            $timestamp - timestamp of this value (optional)
sub inc {
	my $self      = shift; 
	my $labels    = shift;
	my $timestamp = shift;
	$labels       = $self->standardLabels($labels);
	$timestamp    = time()*1000 if !defined($timestamp);

	if ($labels) {
		if (exists($self->{values}->{$labels})) {
			$self->{values}->{$labels}++;
		} else {
			$self->{values}->{$labels} = 1;
		}
		$self->{timestamps}->{$labels} = $timestamp;
	} else {
		if (exists($self->{value})) {
			$self->{value}++;
		} else {
			$self->{value} = 1;
		}
		$self->{timestamp} = $timestamp;
	}
}

# Decreases the value for this metric
# Arguments: $labels - string-encoded map of labels
#            $timestamp - timestamp of this value (optional)
sub dec {
	my $self      = shift; 
	my $labels    = shift;
	my $timestamp = shift;
	$labels       = $self->standardLabels($labels);
	$timestamp    = time()*1000 if !defined($timestamp);

	if ($labels) {
		if (exists($self->{values}->{$labels})) {
			$self->{values}->{$labels}--;
		} else {
			$self->{values}->{$labels} = -1;
		}
		$self->{timestamps}->{$labels} = $timestamp;
	} else {
		if (exists($self->{value})) {
			$self->{value}--;
		} else {
			$self->{value} = -1;
		}
		$self->{timestamp} = $timestamp;
	}
}

# Adds the value for this metric.
# Arguments: $value  - the value to add
#            $labels - string-encoded map of labels
#            $timestamp - timestamp of this value (optional)
sub add {
	my $self      = shift;
	my $value     = shift;
	my $labels    = shift;
	my $timestamp = shift;
	$labels       = $self->standardLabels($labels);
	$timestamp    = time()*1000 if !defined($timestamp);

	if ($labels) {
		if (exists($self->{values}->{$labels})) {
			$self->{values}->{$labels} += $value;
		} else {
			$self->{values}->{$labels} = $value;
		}
		$self->{timestamps}->{$labels} = $timestamp;
	} else {
		if (exists($self->{value})) {
			$self->{value} += $value;
		} else {
			$self->{value} = $value;
		}
		$self->{timestamp} = $timestamp;
	}
}

# Subtracts the value for this metric.
# Arguments: $value  - the value to subtract
#            $labels - string-encoded map of labels
#            $timestamp - timestamp of this value (optional)
sub sub {
	my $self      = shift;
	my $value     = shift;
	my $labels    = shift;
	my $timestamp = shift;
	$labels       = $self->standardLabels($labels);
	$timestamp    = time()*1000 if !defined($timestamp);

	if ($labels) {
		if (exists($self->{values}->{$labels})) {
			$self->{values}->{$labels} -= $value;
		} else {
			$self->{values}->{$labels} = 0-$value;
		}
		$self->{timestamps}->{$labels} = $timestamp;
	} else {
		if (exists($self->{value})) {
			$self->{value} -= $value;
		} else {
			$self->{value} = 0-$value;
		}
		$self->{timestamp} = $timestamp;
	}
}

# DEPRECATE?: Never remove values
# Compute the dead label from the given label string.
# Arguments: $labels - labels to be transformed
# Returns: the dead label string
sub getDeadLabel {
	my $self   = shift;
	my $labels = from_label_string(shift);
	my $rc     = {};

	my $key;
	foreach $key (@{$self->{deadLabels}}) {
		if (exists($labels->{$key})) {
			$rc->{$key} = $labels->{$key};
		}
	}
	$rc->{deadCounter} = "true";

	return $self->standardLabels($rc);
}

# DEPRECATE?: Never remove values
# Checks the retention of all values and moves those series to dead values.
# This is required to ensure that sum() queries in Prometheus always go up.
# Arguments: (none)
sub checkRetention {
	my $self = shift;
	my $now  = time()*1000; # ms

	if ($self->getLabels()) {
		my $label;
		foreach $label ($self->getLabels()) {
			# ignore dead labels!
			if ($label =~ /"deadCounter":"true"/) {
				if (!($self->{enableDeadLabels})) {
					# Delete them
					delete($self->{values}->{$label});
					delete($self->{timestamps}->{$label});
				}
				next;
			}
			my $timestamp = $self->{timestamps}->{$label};
			if ($now - $timestamp > $self->{retentionSeconds}*1000) {
				if ($self->{enableDeadLabels}) {
					$self->add($self->{values}->{$label}, $self->getDeadLabel($label));
				}
				delete($self->{values}->{$label});
				delete($self->{timestamps}->{$label});
			}
		}
	}
}

# Return the metric for exposure
# Arguments: $format - format of exposure (only 'text/plain' supported by now)
sub getExposure {
	my $self   = shift;
	my $format = shift;
	my ($rc, $label, $time);
	$rc   = '';

	# DEPRECATE?: Never remove values
	$self->checkRetention();

	if ($self->getLabels() || exists($self->{value})) {
		# print TYPE
		if (exists($self->{type})) {
			$rc .= '# TYPE '.$self->{name}.' '.$self->{type}."\n";
		}
		# print HELP
		if (exists($self->{help})) {
			$rc .= '# HELP '.$self->{name}.' '.$self->{help}."\n";
		}
		# print simple value
		if (exists($self->{value})) {
			$rc .= $self->{name}.' '.$self->{value}.' '.$self->{timestamp}."\n";
		}
		# print labelled values
		foreach $label ($self->getLabels()) {
			$rc .= $self->{name}.$label.' '.$self->get($label).' '.$self->{timestamps}->{$label}."\n";
		}
	}
	return $rc;
}

# Parse a label string to a hasref.
# Arguments: $s - label string
sub from_label_string {
	my $s  = shift;
	my $rc = {};

	while ($s =~ /([^\{\},\s=]+)\s*=\s*"([^"\{\}]*)"/g) {
		my $key = $1;
		my $val = $2;
		$rc->{$key} = $val;
	}
	return $rc;
}

# Take a hashref and create a label string from it.
# Arguments: $labels - hashref to labels
sub to_label_string {
	my $labels = shift;

	my @KEYS  = sort(keys(%{$labels}));
	my @PARTS = ();
	my $key;
	foreach $key (@KEYS) {
		my $s = $key.'="'.$labels->{$key}.'"';
		push(@PARTS, $s);
	}

	return "{".join(',', @PARTS)."}";
}

1;
