package T016ApExportMetricTest;
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

	my $s = '{environment="test",status="2xx"}';
	my $actual = ApExportMetrics::from_label_string($s);
	if ((scalar(keys(%{$actual})) != 2) || !exists($actual->{environment}) || !exists($actual->{status}) ||
		($actual->{environment} ne 'test') || ($actual->{status} ne '2xx')) {
		return "#from_label_string() failed (expected: {environment=\"test\",status=\"2xx\"}, actual: ".ApExportMetrics::to_label_string($actual).")";
	}
}

1;
