#!/usr/bin/env perl
#----------------------------------------------------------------
# hatteras_io_error_detector.pl
#
# Detect i/o errors on hatteras at RENCI.
#
#----------------------------------------------------------------
# Copyright(C) 2018 Jason Fleming
#
# This file is part of the ADCIRC Surge Guidance System (ASGS).
#
# The ASGS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ASGS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the ASGS.  If not, see <http://www.gnu.org/licenses/>.
#----------------------------------------------------------------
use strict;
use warnings;
use Getopt::Long;
#
my $outfile = "null";
#
sub stderrMessage($$);
#
GetOptions(
           "outfile=s" => \$outfile
           );
#
#
my $slurm_job_id = "null";
my $process = "null";
my $subdir = "null";
unless(open(OUTFILE,"<$outfile")) {
   stderrMessage("ERROR","Could not open $outfile for reading: $!.");
} else {
   while(<OUTFILE>) {
      # look for slurm job ID
      if ( $_ =~ /SLURM Job ID (\d+);/ ) {
         $slurm_job_id = $1;
         &stderrMessage("INFO","Looking for unusual error messages for SLURM job ID $slurm_job_id.");
      }
      # look for specific error message 
      if ( $_ =~ /(\d+), application called MPI_Abort/ ) { 
         $process = $1;
         $subdir = sprintf("PE%04d",$process);
         &stderrMessage("WARNING","Process $process in subdirectory $subdir called MPI_Abort.");
      }
   }
   close(OUTFILE);
}
my $i = 0;
while (1) {
   my $dirname = sprintf("PE%04d",$i);
   if ( -d $dirname ) { 
      unless(open(FORT16,"<$dirname/fort.16")) {
         &stderrMessage("ERROR","Could not open $subdir/fort.16 for reading: $!.");
         last;
      } else { 
         while(<FORT16>) {
            #if ( $_ =~ /INFO: readNetCDFHotstart: Opening hot start file/ ) {
            #my $line = <FORT16>;
            #if ( $line && $line =~ /ERROR: check_err: NetCDF: HDF error/ ) {
            if ( $_ =~ /ERROR: check_err: NetCDF: HDF error/ ) {
               &stderrMessage("ERROR",$_);
               unless(open(RESULT,">>netcdf_io.error") ) {
                  &stderrMessage("ERROR","Received NetCDF HDF error: $!.");
                  die;
               }
               printf RESULT "File i/o error message in file $dirname/fort.16 from process $i when attempting to access netcdf file.\n";
               close(RESULT);
               last;
            }   
         }
         close(FORT16);
      }
   } else {
      last;
   }
   $i++;
}


sub stderrMessage ($$) {
   my $level = shift;
   my $message = shift;
   my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
   (my $second, my $minute, my $hour, my $dayOfMonth, my $month, my $yearOffset, my $dayOfWeek, my $dayOfYear, my $daylightSavings) = localtime();
   my $year = 1900 + $yearOffset;
   my $theTime = "[$year-".sprintf("%3s",$months[$month])."-".sprintf("%02d",$dayOfMonth)."-T".sprintf("%02d",$hour).":".sprintf("%02d",$minute).":".sprintf("%02d",$second)."]";
   printf STDERR "$theTime $level: hatteras_io_error_detector.pl: $message\n";
}
