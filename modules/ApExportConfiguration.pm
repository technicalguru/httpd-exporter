package ApExportConfiguration;
use strict;
use warnings;

# Constructor.
# Arguments: $configFile - location of config file
sub new {
	my $class = shift;
	my $self  = { 
		'configFile'  => shift,
		'general'     => {},
		'logFormats'  => [],
		'locations'   => {},
	};
	my $rc = bless $self, $class;
	$rc->read();
	return $rc;
}

# Reads the configuration file.
# Called from constructor.
# Arguments: (none)
sub read {
	my $self = shift;
	if (open(FIN, '<'.$self->{configFile})) {
		my $currentSection;
		while (<FIN>) {
			chomp;
			my $line = $_;
			# Ignore some lines
			next if $line =~ /^#/;
			next if $line =~ /^\s*$/;

			# New section starts
			if ($line =~ /^\s*\[(.*)\]\s*$/) {
				$currentSection = $1;
			} elsif ($currentSection =~ /^General$/i) {
				my ($key, $value) = split(/\s*=\s*/, $line, 2);
				$self->setGeneral($key, $value);
			} elsif ($currentSection =~ /^LogFormats$/i) {
				$self->addLogFormat($line);
			} else {
				my ($key, $value) = split(/\s*=\s*/, $line, 2);
				$self->setLocationValue($currentSection, $key, $value);
			}
		}
		close(FIN);
	} else {
		die 'Cannot read configuration file: '.$self->{configFile}."\n";
	}
}

# Returns the value from the [General] section.
# Arguments: $key - key of value
sub getGeneral {
	my $self = shift;
	my $key  = shift;

	return $self->{general}->{$key};
}

# Sets the value in the [General] section.
# Arguments: $key   - key of value
#            $value - value
sub setGeneral {
	my $self  = shift;
	my $key   = shift;
	my $value = shift;
	$self->{general}->{$key} = $value;
}

# Returns the log formats
# Arguments: (none)
sub getLogFormats {
	my $self   = shift;
	return $self->{logFormats};
}

# Adds a log format.
# Arguments: $format - the format to be added
sub addLogFormat {
	my $self   = shift;
	my $format = shift;
	push(@{$self->{logFormats}}, $format);
}

# Sets a configuration value for a specific location.
# Arguments: $location - Location
#            $key      - key of value
#            $value    - value
sub setLocationValue {
	my $self     = shift;
	my $location = shift;
	my $key      = shift;
	my $value    = shift;

	if (!exists $self->{locations}->{$location}) {
		$self->{locations}->{$location} = {};
		$self->{locations}->{$location}->{location} = $location;
	}

	$self->{locations}->{$location}->{$key} = $value;
}

# Returns the list of all locations
# Arguments: (none)
sub getLocations {
	my $self     = shift;

	return (keys(%{$self->{locations}}));
}

# Returns the config of this location
# Arguments: $location - the location expression
sub getLocation {
	my $self     = shift;
	my $location = shift;

	return $self->{locations}->{$location};
}

1;

