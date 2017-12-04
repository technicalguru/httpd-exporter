package T010ApExportMatcherTest;
use strict;
use warnings;

# Constructor.
# Arguments: $testSuite - the test suite this test belongs to
sub new {
	my $class = shift;
	my $self  = { 
		'testSuite'  => shift,
	};
	my $rc = bless $self, $class;
	return $rc;
}

# Execute the Test Case
# Arguments: (none)
# Returns: error message if test case failed, 0 otherwise
sub execute {
	my $self = shift;
	my $key;

	# Testing the matcher
	# Simple test: each expression
	my $formatTests = {
		'%{HOSTNAME:value}' => '10.244.0.176',
		'%{INT:value}'      => '80',
		'%{IP:value}'       => '10.244.0.176',
		'%{NOTSPACE:value}' => '-',
		'%{HTTPDATE:value}' => '01/Dec/2017:16:41:09 +0000',
		'%{REQUEST_LINE}'   => 'GET /processQueue HTTP/1.1',
		'%{QS:value}'       => '"curl/7.38.0"',
		'%{HOSTNAME:hostname}(:%{INT:port})?' => 'virtualhostname',
		'%{HOSTNAME:hostname}(:%{INT:port})?' => 'virtualhostname:80',
		'(%{QS:value}|-)'   => '"any string"',
	};
	foreach $key (keys(%{$formatTests})) {
		my $matcher = new ApExportMatcher([$key]);
		my $actual = $matcher->matchLog($formatTests->{$key});
		if (!defined($actual)) {
			return "#matchLog($key) failed with ".$formatTests->{$key};
		}
    }

	return 0;
}

1;
