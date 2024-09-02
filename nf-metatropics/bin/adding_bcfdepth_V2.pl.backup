#!/usr/bin/perl

use strict;
use File::Basename;

my $depthSAM = $ARGV[0];
my $tsvNF = $ARGV[1];
my $finalFile = $ARGV[2];
my $consensus = $ARGV[3];


sub updateReport {
  my @inputs = @_;
  my $id = $inputs[0];
  $id=~s/\.txt|//g;
  $id=~s/.+\.//g;
  #print "$id\n";

  my $line = `grep -w $id $inputs[1]`;
  chomp($line);
  #print "$line";
  my @parameters = split(/\t/,$line);

  my $depth = `tail -n 1 $inputs[0]`;
  chomp($depth);
  #print "$depth";
  my @samtoolDepth = split(/\t/,$depth);

  my $sequence = `grep -v \"\>\" $inputs[2]`;
  chomp($sequence);
  $sequence=~s/\n//g;
  #print "$sequence";
  my @bases = split(//,$sequence);
  my ($A,$T,$C,$G,$N)=0;
  foreach my $base (@bases){
    if(uc($base) eq "A"){
        $A++;;
    }elsif(uc($base) eq "T"){
        $T++;
    }elsif(uc($base) eq "C"){
        $C++;
    }elsif(uc($base) eq "G"){
        $G++;
    }elsif(uc($base) eq "N"){
        $N++;
    }
  }
  my $knowBases=$A+$T+$C+$G;
  #print "$A $T $C $G $N $knowBases $samtoolDepth[2]\n";
  my $consensusCov=($knowBases/$samtoolDepth[2])*100;
  my $N_percent=($N/$samtoolDepth[2])*100;

  #my $results = "$parameters[0]\t$parameters[1]\t$parameters[2]\t$parameters[3]\t$parameters[4]\t$parameters[5]\t$parameters[6]\t$samtoolDepth[5]\t$samtoolDepth[6]\t$consensusCov\t$N_percent\t$parameters[9]\t$parameters[10]\t$samtoolDepth[7]\n";
  my $results = "$parameters[1]\t$parameters[2]\t$parameters[3]\t$parameters[4]\t$parameters[5]\t$parameters[6]\t$samtoolDepth[5]\t$samtoolDepth[6]\t$consensusCov\t$N_percent\t$parameters[9]\t$parameters[10]\t$samtoolDepth[7]\n";

  #print "$results";

  return $results;


}

if(-e $finalFile){
  open(FIN,">>$finalFile");
  #print FIN "mais um\n";
  my $update = updateReport($depthSAM,$tsvNF,$consensus);
  print FIN $update;
  close FIN;

}else {
  open(FIN,">$finalFile");
  open(TSV,"$tsvNF");
  my $line;
  while($line=<TSV>){
    chomp($line);
    if($line=~m/VirusName/){
      my @temp=split(/\t/,$line);
      print FIN "$temp[0]\t$temp[1]\t$temp[2]\t$temp[3]\t$temp[4]\t$temp[5]\t\"Coverage\"\t\"DepthAverage\"\t\"ConsensusCov\"\t\"N_content\"\t$temp[8]\t$temp[9]\tMeanBaseQuality\n";
    }
  close TSV;
  my $update = updateReport($depthSAM,$tsvNF,$consensus);
  print FIN $update;
  close TSV;
  close FIN;


  }
}
