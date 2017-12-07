package T008ApExportMetricTest;
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
	$m->inc('{environment="dev"}');
	$m->inc('{hostname="localhost"}');
	$m->set(1000);
	my $actual = $m->get();
	if ($actual != 1000) {
		return "#set() failed (expected: 1000, actual $actual)";
	}
	return 0;
}

1;
