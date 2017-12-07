package ApExportCollector;
use strict;
use warnings;
use ApExportMetrics;

# Constructor.
# Arguments: $metricsFile - location of metrics file
sub new {
	my $class = shift;
	my $self  = { 
		'metricsFile'  => shift,
		'metrics'      => {},
	};
	my $rc = bless $self, $class;
	$rc->load();
	return $rc;
}

# Load existing metrics file if it exists
# Arguments: (none)
sub load {
	my $self = shift;
	if (open(FIN, '<'.$self->{metricsFile})) {
		my $currentSection;
		while (<FIN>) {
			chomp;
			my $line = $_;
			# Ignore some lines
			next if $line =~ /^\s*$/;

			if ($line =~ /^#\s+HELP\s+([^\s]+)\s+(.*)/) {
				my $metrics = $1;
				my $help    = $2;
				my $m = $self->getOrCreateMetrics($metrics);
				$m->setHelp($help);
			} elsif ($line =~ /^#\s+TYPE\s+([^\s]+)\s+([A-Za-z]+)/) {
				my $metrics = $1;
				my $type   = $2;
				my $m = $self->getOrCreateMetrics($metrics);
				$m->setType($type);
			} elsif ($line =~ /^\s*([-_\.A-Za-z0-9\{\}]+)(\{\s*([^=]+\s*=\s*"[^"]+")(\s*,\s*[^=]+\s*=\s*"[^"]+")*\s*\})?\s+(\d+(\.\d+)?)\s+(\d+)?/) {
				my $metrics   = $1;
				my $labels    = $2;
				my $value     = $5;
				my $timestamp = $7;
				my $m = $self->getOrCreateMetrics($metrics);
				$m->set($value, $labels, $timestamp);
			}
		}
		close(FIN);
	}
}

# Gets the metrics with given name.
# Used when checking whether a metrics exists.
# Arguments: $name - name of metrics
# Returns: the metrics or undef
sub getMetrics {
	my $self = shift;
	my $name = shift;

	if (exists $self->{metrics}->{$name}) {
		return $self->{metrics}->{$name};
	}

	return undef;
}

# Gets or creates the given metric.
# Arguments: $name - name of metrics
#            $type - type of metrics
#            $help - help text for metrics
sub getOrCreateMetrics {
	my $self = shift;
	my $name = shift;
	my $type = shift;
	my $help = shift;

	if (!exists $self->{metrics}->{$name}) {
		$self->{metrics}->{$name} = new ApExportMetrics($name);
		$self->{metrics}->{$name}->setType($type) if defined($type);
		$self->{metrics}->{$name}->setHelp($help) if defined($help);
	}

	return $self->{metrics}->{$name};
}

# Save metrics file
# Arguments: (none)
sub save {
	my $self   = shift;
	my $format = shift;
	my $name;

	if (open(FOUT, '>'.$self->{metricsFile}.'.part')) {
		foreach $name (keys(%{$self->{metrics}})) {
			my $metric = $self->{metrics}->{$name};
			print FOUT $metric->getExposure($format)."\n";
		}
		close(FOUT);
		rename($self->{metricsFile}.'.part', $self->{metricsFile});
	} else {
		print STDERR "Cannot save metrics: ".$self->{metricsFile}."\n";
	}
}

1;

