use strict;
use warnings;
use Getopt::Long;

my ($infa, $min_fragment_length, $max_fragment_length, $outpref,$gxf,$numN);

GetOptions(
   "help|?" =>\&USAGE,
   "fa:s"=>\$infa,
   "minlen:s"=>\$min_fragment_length,
   "maxlen:s"=>\$max_fragment_length,
   "out:s"=>\$outpref,
   "numN:s"=>\$numN,
   "gxf:s"=>\$gxf,
)  or &USAGE;
&USAGE unless ($infa and $outpref);



sub USAGE{
my $info = <<"INFO";
 
   \033[42;37m  split large genome into shorter scaffolds       \033[0m
   \033[42;37m  according to GAPS (Ns in sequence)              \033[0m
   \033[47;32m     e-mail: biomarble\@163.com                    \033[0m
   \033[47;32m     github:github.com/biomarble/splitLargeGenome \033[0m

Options:
    -fa        <file>      required       input genome sequences file, fasta format
    -gxf       <file>      optional       gtf/gff file for the fasta file, default not set
    -out       <str>       required       output file prefix
    -numN      <num>       optional       minimum length of Ns as split separator, default 10
    -minlen    <num>       optional       minmum  scaffold length in output, default 300000000
    -maxlen    <num>       optional       maximum fragment length in output, default 500000000
                                          maxlen must large than minlen


USAGE example:
perl  $0  -fa genome.fa -minlen 300000000 -maxlen 500000000 -gxf gene.gtf -out genome.sep -numN 10


Results:
genome.sep.fa         : scaffold sequences with length between 300~500Mb
genome.sep.detail.txt : split position details
gene.sep.gtf          : new gtf file with new positions according to the detail file
                         only exists when -gxf was set

INFO

print $info; 
exit;         
}


$numN=10 if !defined $numN;
$min_fragment_length=300000000 if !defined $min_fragment_length;
$max_fragment_length=500000000 if !defined $max_fragment_length;

my $ext;
if(defined $gxf){
 $ext = ($gxf=~ /\.(gff3|gff|gtf)$/i) ? $1 : die "Error: $gxf file extension not valid(gtf/gff/gff3)\n";
}

unlink "$outpref.fa" if -e "$outpref.fa";
unlink "$outpref.detail.txt" if -e "$outpref.detail.txt";

die "minlen should be a positive integer\n" unless $min_fragment_length =~ /^\d+$/;
die "maxlen should be a positive integer\n" unless $max_fragment_length =~ /^\d+$/;
die "maxlen should be larger than minlen\n" if $max_fragment_length <= $min_fragment_length;

$/ = ">";
open my $in, "<", $infa or die "Could not open input file: $!";

while (<$in>) {
    chomp;
    next if ($_ eq "");
    my ($id, $genome_sequence) = split /\n/, $_, 2;
    $genome_sequence =~ s/[\n\r]//g;
    $id =~ s/\s.*$//g;

    my $current_fragment = "";
    my $fragment_length = 0;
    my $current_position = 0;
    my $realS = 0;
    my $realLen=length($genome_sequence);

    while ($genome_sequence =~ /(N{$numN,})/ig) {
        my $match_length = length($1);
        my $match_start = $-[0];

        my $segment_length = $match_start - $current_position;
        $current_fragment .= substr($genome_sequence, $current_position, $segment_length + $match_length);
        $fragment_length += $segment_length + $match_length;
        $current_position = $match_start + $match_length;

        if ($fragment_length >= $min_fragment_length) {
            my $end = $realS + $fragment_length - 1;
            warn "Fragment Length Not Satisfied: $id:$realS-$end\t" . sprintf("%.2f", $fragment_length / 1_000_000) . "M\nPlease lower minlen or increase the maxlen\n"
                if ($fragment_length > $max_fragment_length);

            process_fragment($id, $current_fragment, $realS, $fragment_length, $outpref,$realLen);
            $realS = $current_position;
            $current_fragment = "";
            $fragment_length = 0;
        }
    }

    my $remaining_length = length($genome_sequence) - $realS;
    if ($remaining_length > 0) {
        my $remaining_fragment = substr($genome_sequence, $realS, $remaining_length);
        process_fragment($id, $remaining_fragment, $realS, $remaining_length, $outpref,$realLen);
    }
}
close $in;

$/="\n";

if(defined $gxf){
&process_gxf($gxf,"$outpref.detail.txt","$outpref.$ext");
}

sub process_fragment {
    my ($id, $fragment, $start_position, $length, $outpref,$realLen) = @_;
    my $end = $start_position + $length - 1;
    $start_position++;
    $end++;

    open my $out_fa, ">>", "$outpref.fa" or die "Could not generate output fasta file: $!";
    if($realLen == $length){
       print $out_fa ">$id\n";
    }else{
       print $out_fa ">$id\_$start_position\_$end\n";
    }
    print $out_fa join("\n",unpack("(A50)*",$fragment)),"\n";
    close $out_fa;

    open my $out_txt, ">>", "$outpref.detail.txt" or die "Could not generate output detail file: $!";
    print $out_txt "$id\t$start_position\t$end\n";
    close $out_txt;
}

sub process_gxf{
    my ($ingxf,$region,$outgxf)=@_;
    my %reg;
    open IN,"<",$region or die "Could not open output detail file $region\n";
    while(<IN>){
       chomp;
       my ($chr,$s,$e)=split /\t/,$_;
       $reg{$chr}{$s}{$e}=1;
    }
    close IN;
    open IN,"<",$ingxf or die "$ingxf file could not open!\n";
    open OUT,">","$outgxf" or die "cannot generate result file: $outgxf\n";
    while(<IN>){
      chomp;
      next if($_=~/^\s*$/);
      if($_=~/^#/){print "$_\n";next;}
      my ($chr,$source,$type,$start,$end,$else)=split /\t/,$_,6;
      foreach my $s(sort keys %{$reg{$chr}}){
          foreach my $e(sort keys %{$reg{$chr}{$s}}){
             next if($e <$start or $s>$end);
             my $newS=$start-$s+1;
             my $newE=$end-$s+1;
             die  "feature  splitted into diff region $chr:$s-$e:\n$_\n" if($end>$e);
             if(scalar keys %{$reg{$chr}}==1){
                 print OUT "$chr\t$source\t$type\t$newS\t$newE\t$else\n";
             }else{
                 print OUT "$chr\_$s\_$e\t$source\t$type\t$newS\t$newE\t$else\n";
             }
          }
      }
    }
    close IN;
    close OUT;
}
