#!/usr/local/bin/perl
use strict;
use warnings;
use FindBin;
use Cwd            qw( abs_path );
use File::Basename qw( dirname );
use Sys::Hostname;
use Socket;

# Get our path
use lib "$FindBin::RealBin";
use lib "$FindBin::RealBin/modules";
use lib "$FindBin::RealBin/test";

# Load our module
use ApExporter;

# Special argument --test - perform system tests to check whether
# the environment fits our requirements
if (exists($ARGV[0]) && ($ARGV[0] eq '--test')) {
	exit ApExporter::performTests();
}
# Special argument --test-loop - run idle loop 
# (useful in containers to check reason for errors)
if (exists($ARGV[0]) && ($ARGV[0] eq '--test-loop')) {
	ApExporter::performDummyLoop();
}

# Get the config file from cmd argument
my $configFile = shift;

# Fallback: Environment variable
if (!$configFile) {
	$configFile = $ENV{'APEXPORT_CONFIG_FILE'};
}

# Fallback: Default location
if (!$configFile) {
	$configFile = '/etc/httpd-exporter/exporter.conf';
}

# Check existance of config file
if (!-f $configFile) {
	die "Cannot find configuration: $configFile\n";
}

# Run the daemon
my $daemon = new ApExporter($configFile);
$daemon->run();

# We shall never get here
exit 0;


