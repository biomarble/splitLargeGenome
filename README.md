[中文说明]()

# split large genome fasta and gtf/gff into shorter scaffolds 

- Large genome (e.g. wheat) have long single chromosome, which some software or file format not support.
- `.bai` (bam index file) only support chromosomes shorter than $2^{29}-1$ Mb. 
- `.csi` extend the limit to $2^{44}-1$ Mb, but support for `.csi` is not widely applied in all softwares.
- `.tbi` (variant index file) have the same limitation, but the extended `.csi` format is not supported by some software (like GATK).

## Summary

This script can :
1. split the genome sequences (fasta format) into smaller scaffolds
2. split point is always the GAP sequence (a certain length of Ns)
3. the gtf/gff chromosome name and feature coordinates can be converted simultaneously.(optional)

## Usage


### Installation

1. download repository as [zip](https://github.com/biomarble/splitLargeGenome/archive/refs/heads/main.zip)
2. unzip `splitLargeGenome-main.zip`
3. just run.
```sh
perl splitLargeGenome-main/splitLargeGenome.pl
```

### Options
```php
    -fa        <file>      required       input genome sequences file, fasta format
    -gxf       <file>      optional       gtf/gff file for the fasta file, default not set
    -out       <str>       required       output file prefix
    -numN      <num>       optional       minimum length of Ns as Separator, default 10
    -minlen    <num>       optional       minmum  scaffold length in output, default 300000000
    -maxlen    <num>       optional       maximum fragment length in output, default 500000000
```

### Use example

Split a genome into smaller fragments of 300M~500M in length using at least 10 Ns as separators, and update the corresponding gene.gtf with the new coordinates

```sh
perl  splitLargeGenome.pl  -fa genome.fa -minlen 300000000 -maxlen 500000000 -gxf gene.gtf -out genome.sep  -numN
```
### Results

```yaml
genome.sep.fa         : scaffold sequences with length between 300~500Mb
genome.sep.detail.txt : split position details
gene.sep.gtf          : new gtf file with new positions according to the detail file
                         only exists when -gxf was set
```

## report bugs

any suggestions or bug reports you can:

- [raise an issue](https://github.com/biomarble/splitLargeGenome/issues)
-  [send an email](mailto:biomarble@163.com)
