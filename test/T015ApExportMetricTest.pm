package T015ApExportMetricTest;
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

	my $l = {
		'environment' => 'test',
		'status'      => '2xx',
	};
	my $actual = ApExportMetrics::to_label_string($l);
	if ($actual ne '{environment="test",status="2xx"}') {
		return "#to_label_string() failed (expected: {environment=\"test\",status=\"2xx\"}, actual: $actual)";
	}

	return 0;
}

1;
