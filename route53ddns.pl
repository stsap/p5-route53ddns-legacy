#!/usr/bin/perl --

use strict;
use warnings;
use AWS::Route53::Simple;
use LWP::Simple qw(get);
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);


my %credentials = (
    AccessKey => $ENV{"AWS_ACCESS_KEY"},
    SecretAccessKey => $ENV{"AWS_SECRET_KEY"}
);
GetOptions(
    "AccessKey|id|i=s" => \$credentials{AccessKey},
    "SecretAccessKey|secret|key|k=s" => \$credentials{SecretAccessKey},
    "zone|z=s" => \my $zone,
    "host|h=s" => \my @host
);
$zone = ($zone =~ /\.$/msx) ? $zone: $zone.".";

my $gip = get('http://169.254.169.254/latest/meta-data/public-ipv4');

die("connection failed.") if (not $gip);

my $r53 = AWS::Route53::Simple->new(%credentials);
my $zones = $r53->returnType("perl")->action("ListHostedZones")->send();
my @targetZone = grep({ $_->{"Name"} eq $zone } @{$zones->{"HostedZones"}->{"HostedZone"}});
(my $zoneId = $targetZone[0]->{"Id"}) =~ s/^.*\///msx;

die("failed to get hosted zone ID.") if (not $zoneId);

my @actions;
map({ push(@actions, {Action => "UPSERT", Type => "A", Name => $_, TTL => 300, Value => $gip}); } @host);
$r53->action("ChangeResourceRecordSets")->param(\@actions)->send({ZoneID => $zoneId});

