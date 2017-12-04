package T011ApExportMatcherTest;
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

	# Complex test of matcher
	my $format1 = "%{HOSTNAME:hostname}(:%{INT:port})? %{IP:clientip} %{NOTSPACE:rlogname} %{NOTSPACE:user} \\[%{HTTPDATE:timestamp}\\] \"%{REQUEST_LINE}\" %{INT:status} %{INT:bytes_sent} (%{QS:referrer}|-) (%{QS:agent}|-)";
	my $format2 = "%{IP:clientip} %{NOTSPACE:rlogname} %{NOTSPACE:user} \\[%{HTTPDATE:timestamp}\\] \"%{REQUEST_LINE}\" %{INT:status} %{INT:bytes_sent} (%{QS:referrer}|-) (%{QS:agent}|-)";
	my $format3 = "%{IP:clientip} %{NOTSPACE:rlogname} %{NOTSPACE:user} \\[%{HTTPDATE:timestamp}\\] \"%{REQUEST_LINE}\" %{INT:status} %{INT:bytes_sent}";
	my $matcher = new ApExportMatcher([$format1, $format2, $format3]);
	my $line = "10.244.0.176 - - [01/Dec/2017:16:41:09 +0000] \"GET /processQueue HTTP/1.1\" 200 433 \"-\" \"curl/7.38.0\"\n";

	my $actual = $matcher->matchLog($line);
	if (!defined($actual)) {
		return "#matchLog() failed";
	}

	return 0;
}

1;
