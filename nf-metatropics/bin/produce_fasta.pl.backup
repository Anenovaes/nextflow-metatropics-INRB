#!/usr/bin/perl

use strict;
use File::Basename;

my $report = $ARGV[0];
my $readsEM = $ARGV[1];
my $DB = $ARGV[3];
my $fastq = $ARGV[2];
my $min=$ARGV[4];

$min=$min*100;

system("samtools faidx $DB");

my $sample=basename($report);
$sample=~m/\..+/;
$sample=$`;

open(REP,"$report");

my $count = 0;

my $line;
while($line=<REP>){
    if($line=~m/VirusName/){
      next;
    }
    chomp($line);
    $line=~s/\"//g;
    #print $sample."\t".$line."\n";
    my @virus = split(/\t/,$line);
    if($virus[5]>=$min){
      $count++;
    #if($virus[5]>=0.1){
    #if($virus[5]>=0.01){
      system("grep -w $virus[2] $readsEM | awk '{print \$1}' | sort | uniq > $sample.$virus[2].reads");
      my $taxID=`grep -m 1 -w $virus[2] $DB`;
      chomp($taxID);
      $taxID=~s/\>//g;
      #print $taxID."\n";
      system("samtools faidx $DB \"$taxID\" > $sample.$virus[2].REF.fasta");
      system("cp $fastq $sample.$virus[2].fastq");
      #print("$virus[2]");
    }
}
close REP;

if($count==0){
  system("touch $sample.novirus.REF.fasta");
  system("touch $sample.novirus.fastq");
  system("touch $sample.novirus.reads");
  print "TSV empty\n";
}

#barcode02_classification_results,
