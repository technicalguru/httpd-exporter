package T009ApExportMetricTest;
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
	my $actual = $m->getExposure('/text/plain');
	if (   ($actual !~ /test_metric\{environment="dev"\} 1 \d+/)
		|| ($actual !~ /test_metric\{environment="test"\} 1 \d+/)
		|| ($actual !~ /test_metric\{hostname="localhost"\} 1 \d+/)
		|| ($actual !~ /test_metric 1000 \d+/)) {
		return "#getExposure('text/plain') failed:\n".
			"Expected:\n".
			"test_metric{environment=\"dev\"} 1 <timestamp>\n".
			"test_metric{environment=\"test\"} 1 <timestamp>\n".
			"test_metric{hostname=\"localhost\"} 1 <timestamp>\n".
			"Actual:\n".
			$actual;
	}

	return 0;
}

1;
