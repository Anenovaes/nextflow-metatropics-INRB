#!/usr/bin/perl

use strict;
use File::Basename;
use Bio::SeqIO;

my $sampleName = $ARGV[0];
my $snpFile = $ARGV[1];
my $bamcountFile = $ARGV[2];
my $depthThreshold = $ARGV[3];
my $agreementThreshold = $ARGV[4];
my $vcfFile = $ARGV[5];
my $alignment = $ARGV[6];


my $inseq = Bio::SeqIO->new(-file =>"$alignment",
                                    -format => 'fasta');
my ($id,$sequence);
while (my $seq = $inseq->next_seq) {
    my $tempid = $seq->id;
    my $tempsequence = $seq->seq;
    if($tempid=~m/$sampleName/){
        $id=$tempid;
        $sequence=$tempsequence;
    }   
}
my @nts=split(//,$sequence);



my $inRef = Bio::SeqIO->new(-file =>"$alignment",
                                    -format => 'fasta');

my $refSeq = $inRef->next_seq;
my $refID=$refSeq->id;
my $refNT=$refSeq->seq;
my @refNTpos=split(//,$refNT);


system("grep \"#\" $vcfFile > $sampleName.annotated.filtered.vcf");

my $line;
my %SNPs;
my @tempArray;
open(SNP,"$snpFile");
while($line=<SNP>){
    chomp($line);
    if($line=~m/$sampleName/){
        @tempArray=split(/,/,$line);
        foreach my $nt (split(/;/,$tempArray[1])){
            #print "$nt\n";
            my @arraySnps=split(/:/,$nt);
            $SNPs{$arraySnps[0]}=$arraySnps[1];
        }
    }


}

open(SEQ,">$sampleName.edited.fasta");

print "Coordinate\tRefCoord\tTotalDepth\tOriginalNucl\tOriginalDepth\tMeanQualOriginal\tAlternativeNucl\tAlternativeDepth\tMeanQualAlternative\tPercetangeDepthAlternative\n";
foreach my $coord (sort {$a <=> $b} (keys %SNPs)){
    my $mutation = $SNPs{$coord};
    my @nucleotides=split(//,$mutation);

    my $realCoord;
    my $gap=0;
    #for(my $j=0;$j<$coord;$j++){
    for(my $j=0;$j<$coord-1;$j++){    
        my $posTemp=$refNTpos[$j];
        if($posTemp eq "-"){
            $gap++;
        }
    }
    $realCoord=$coord-$gap;



    #print "This is coordinate $coord\tThis is muation $nucleotides[0]\t$nucleotides[1]\n";
    my $bamline=`awk -F \"\t\" '{if(\$2==$realCoord) print \$0}' $bamcountFile`;
    chomp($bamline);
    my @bamposition=split(/\t/,$bamline);
    my $depth=$bamposition[3];
    #print scalar(@bamposition)."\n";
    my ($depthOriginal,$qualOriginal,$depthAlternative,$qualAlternative,$percentange);
    for(my $i=4;$i<scalar(@bamposition);$i++){
        if($bamposition[$i]=~m/^$nucleotides[0]\:/){
            my @temp=split(/:/,$bamposition[$i]);
            $depthOriginal=$temp[1];
            $qualOriginal=$temp[3];
            #print $bamposition[$i]."\n";
        }elsif($bamposition[$i]=~m/^$nucleotides[1]\:/){
            my @temp=split(/:/,$bamposition[$i]);
            $depthAlternative=$temp[1];
            $qualAlternative=$temp[3];
            if($depth==0){
                $percentange=($depthAlternative/($depth+1))*100;    
            }elsif($depth>0){
                $percentange=($depthAlternative/$depth)*100;
            }
            #print $bamposition[$i]."\n";
        }
        #print "$i\n";
    }
    #print "coordinate\=$coord\ttotalDepth\=$depth\tdepthOriginal\=$nucleotides[0]\-$depthOriginal\tdepthAlternative\=$nucleotides[1]\-$depthAlternative\n";
    #if(($depth>=$depthThreshold && $percentange>=$agreementThreshold)||$percentange>=90){
    if($depth>=$depthThreshold && $percentange>=$agreementThreshold){
        print "$coord\t$realCoord\t$depth\t$nucleotides[0]\t$depthOriginal\t$qualOriginal\t$nucleotides[1]\t$depthAlternative\t$qualAlternative\t";
        printf("%.2f",$percentange);
        print "\n";
        system("awk -F \"\t\" '{if(\$2==$realCoord) print \$0}' $vcfFile >> $sampleName.annotated.filtered.vcf");
    }else{#if($depth<$depthThreshold && $percentange<$agreementThreshold){
        #print "$coord\t$realCoord\t$depth\t$nucleotides[0]\t$depthOriginal\t$qualOriginal\t$nucleotides[1]\t$depthAlternative\t$qualAlternative\t";
        #printf("%.2f",$percentange);
        #print "\tLOWQUALITY\n";
        my $coordPerl=$coord-1;
        $nts[$coordPerl]="n";
    }

}

print SEQ ">$id\n".join("",@nts)."\n";
close SEQ;