package T014ApExportMetricTest;
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
	$m->set(3000, '{environment="test",status="2xx"}', 0);
	$m->checkRetention();
	my $actual = $m->get('{environment="test",status="2xx"}');
	if ($actual != 0) {
		return "#checkRetention() failed (expected: 0, actual: $actual)";
	}
	$actual = $m->get('{deadCounter="true",status="2xx"}');
	if ($actual != 3000) {
		return "#checkRetention() failed (expected: 3000, actual: $actual)";
	}
	return 0;
}

1;
