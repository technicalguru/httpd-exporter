package T001ApExportMetricTest;
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
	my $s = '{key2="value2" , key1 = "value1" }';
	my $actual = $m->standardLabels($s);
	my $expected = '{key1="value1",key2="value2"}';
	if ($actual ne $expected) {
		return "#standardLabels(String) failed (expected: '$expected', actual: '$actual')";
	}
	return 0;
}

1;
