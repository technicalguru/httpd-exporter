package ApExportMatcher;
use strict;
use warnings;

my $REGEX = {
	'HOSTNAME'     => '(?<value>[^\s:]+)',
	'INT'          => '(?<value>\d+)',
	'IP'           => '(?<value>(\d+\.\d+\.\d+.\d+)|([A-Za-z0-9\.]+))',
	'NOTSPACE'     => '(?<value>[^\s]+)',
	'HTTPDATE'     => '(?<value>\d{2}\\/[A-Z][a-z][a-z]\\/\d{4}:\d{2}:\d{2}:\d{2} [-+]\d{4})',
	'REQUEST_LINE' => '(?<method>[A-Z]+)\s+(?<path>[^\s]+)\s+(?<protocol>[A-Z]+)\/(?<protocolVersion>[0-9\.]+)',
	'QS'           => '((?<QX>["\'])(?<value>(\\\\{2})*|(.*?[^\\\\](\\\\{2})*))\g{QX})',
};

# Constructor.
# Arguments: $logFormats
sub new {
	my $class = shift;
	my $self  = { 
		'logFormats'  => shift,
	};
	my $rc = bless $self, $class;
	return $rc;
}

# Matches a log line against any of the log formats defined.
# Arguments: $log - the plain log line
# Returns: hashref of matched variables or undef
sub matchLog {
	my $self = shift;
	my $log  = shift;

	my $format;
	foreach $format (@{$self->{logFormats}}) {
		my $rc = $self->tryMatch($log, $format);
		if (defined($rc)) {
			return $rc;
		}
	}
	return undef;
}

# Tries to match a log line against a specific log format.
# Arguments: $log    - the plain log line
#            $format - the format to be matched
# Returns: hashref of matched variables or undef
sub tryMatch {
	my $self = shift;
	my $log  = shift;
	my $reg  = shift;

	# Replace all occurrences of %{} with appropriate expressions
	my $idx = 0;
	while ($reg =~ /(%\{([^:\}]+)(:([^\}]+))?})/g) {
		my $type = $2;
		my $name = $4;
		my $regex = $REGEX->{$type};
		if (defined($regex)) {
			my $newReg ='';
			my $start = $-[0];
			my $end   = $+[0];
			$newReg .= substr($reg, 0, $start) if $start;
			$regex =~ s/<value>/<$name>/;
			$regex =~ s/<QX>/<Q$idx>/;
			$regex =~ s/\\g\{QX\}/\\g\{Q$idx\}/;
			$newReg .= $regex;
			$newReg .= substr($reg, $end);
			$reg = $newReg;
		} else {
			die "No such expression: $type\n";
		}
		$idx++;
	}

	# Now match it
	if ($log =~ /^$reg/) {
		my $rc = {};
		my $key;
		foreach $key (keys(%+)) {
			$rc->{$key} = $+{$key};
		}
		return $rc;
	}

	return undef;
}


1;

