package T002ApExportMetricTest;
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

	my $m = new ApExportMetrics('test_metric');
	$m->inc('{environment="test"}');
	my $actual = $m->get('{environment="test"}');
	if ($actual != 1) {
		return "#inc(String) failed (expected: 1, actual: $actual)";
	}

	return 0;
}

1;
