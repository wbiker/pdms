#!/usr/bin/env perl
use v5.14;
use FindBin qw($Bin);
use lib "$Bin/lib";
use Pdms::Cli;

Pdms::Cli->run;
