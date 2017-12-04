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
		'name'   => shift,
		'values' => {},
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

# standardizes the labels given for storing in this metric
sub standardLabels {
	my $self  = shift; 
	my $in    = shift;

	if ($in) {
		my $labels = ref($in) ? $in : from_json($in);
		my @OUT = ();
		my $key;
		my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
		foreach $key (sort(keys(%{$labels}))) {
			my $k = $coder->encode($key);
			my $v = $coder->encode($labels->{$key});
			chomp $k;
			chomp $v;
			push(@OUT, $k.':'.$v);
		}
		return '{'.join(',', @OUT).'}';
	}
	return '';
}

# Gets the value for this metric.
# Arguments: $labels - JSON-encoded map of labels
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
# Arguments: $value  - the value
#            $labels - JSON-encoded map of labels
sub set {
	my $self   = shift; 
	my $value  = shift;
	my $labels = shift;
	$labels = $self->standardLabels($labels);

	if ($labels) {
		$self->{values}->{$labels} = $value;
	} else {
		$self->{value} = $value;
	}
}

# Increases the value for this metric
# Arguments: $labels - JSON-encoded map of labels
sub inc {
	my $self   = shift; 
	my $labels = shift;
	$labels = $self->standardLabels($labels);

	if ($labels) {
		if (exists($self->{values}->{$labels})) {
			$self->{values}->{$labels}++;
		} else {
			$self->{values}->{$labels} = 1;
		}
	} else {
		if (exists($self->{value})) {
			$self->{value}++;
		} else {
			$self->{value} = 1;
		}
	}
}

# Decreases the value for this metric
# Arguments: $labels - JSON-encoded map of labels
sub dec {
	my $self   = shift; 
	my $labels = shift;
	$labels = $self->standardLabels($labels);

	if ($labels) {
		if (exists($self->{values}->{$labels})) {
			$self->{values}->{$labels}--;
		} else {
			$self->{values}->{$labels} = -1;
		}
	} else {
		if (exists($self->{value})) {
			$self->{value}--;
		} else {
			$self->{value} = -1;
		}
	}
}

# Adds the value for this metric.
# Arguments: $value  - the value to add
#            $labels - JSON-encoded map of labels
sub add {
	my $self   = shift;
	my $value  = shift;
	my $labels = shift;
	$labels = $self->standardLabels($labels);

	if ($labels) {
		if (exists($self->{values}->{$labels})) {
			$self->{values}->{$labels} += $value;
		} else {
			$self->{values}->{$labels} = $value;
		}
	} else {
		if (exists($self->{value})) {
			$self->{value} += $value;
		} else {
			$self->{value} = $value;
		}
	}
}

# Subtracts the value for this metric.
# Arguments: $value  - the value to subtract
#            $labels - JSON-encoded map of labels
sub sub {
	my $self   = shift;
	my $value  = shift;
	my $labels = shift;
	$labels = $self->standardLabels($labels);

	if ($labels) {
		if (exists($self->{values}->{$labels})) {
			$self->{values}->{$labels} -= $value;
		} else {
			$self->{values}->{$labels} = 0-$value;
		}
	} else {
		if (exists($self->{value})) {
			$self->{value} -= $value;
		} else {
			$self->{value} = 0-$value;
		}
	}
}

# Return the metric for exposure
# Arguments: $format - format of exposure (only 'text/plain' supported by now)
sub getExposure {
	my $self   = shift;
	my $format = shift;
	my ($rc, $label, $time);
	$time = time;
	$rc   = '';

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
			$rc .= $self->{name}.' '.$self->{value}.' '.$time."\n";
		}
		# print labelled values
		foreach $label ($self->getLabels()) {
			$rc .= $self->{name}.$label.' '.$self->get($label).' '.$time."\n";
		}
	}
	return $rc;
}

1;
