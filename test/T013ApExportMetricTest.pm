package T013ApExportMetricTest;
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
	$m->addDeadLabel('status');
	my $actual = $m->getDeadLabel('{"environment":"test","status":"2xx"}');
	if ($actual ne '{"deadCounter":"true","status":"2xx"}') {
		return "#getDeadLabel() failed (expected: '{\"deadCounter\":\"true\",\"status\":\"2xx\"}', actual: $actual)";
	}
	return 0;
}

1;
