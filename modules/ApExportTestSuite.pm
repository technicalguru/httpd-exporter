package ApExportTestSuite;
use strict;
use warnings;

# Constructor.
# Arguments: $logFormats
sub new {
	my $class = shift;
	my $self  = { 
		'testDir'  => shift,
	};
	my $rc = bless $self, $class;
	return $rc;
}

# perform the tests
# Arguments: (none)
# Returns: int - number of errors
sub execute {
	my $self = shift;
	my $rc   = 0;

	my @TESTS = ();

	# Read the test directory
	if (opendir(DIRIN, $self->{testDir})) {
		my @ENTRIES = readdir(DIRIN);
		closedir(DIRIN);
		my ($entry, $testName);

		foreach $entry (@ENTRIES) {
			next if -d $entry;
			next if $entry eq '.';
			next if $entry eq '..';
			next if $entry !~ /Test\.pm$/;

			$testName = $entry;
			$testName =~ s/\.pm$//;

			require "$testName.pm";
			import $testName;
			push(@TESTS, $testName);
		}

		@TESTS = sort(@TESTS);
		my $total  = scalar(@TESTS);
		my $failed = 0;
		my $passed = 0;
		my $idx    = 1;
		$| = 1;
		foreach $testName (@TESTS) {
			print "$idx/$total...";
			my $test = $testName->new($self);
			my $err  = $test->execute();
			if ($err) {
				print "failed: $testName - $err\n";
				$failed++;
			} else {
				print "OK\n";
				$passed++;
			}
			$idx++;
		}
		print "Test Summary: $total total, $failed failed, $passed passed\n";
	} else {
		print STDERR "Cannot execute tests in ".$self->{testDir}."\n";
		$rc = 1;
	}
	return $rc;
}


1;

