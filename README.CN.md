# 分割大基因组 FASTA 和 GTF/GFF 文件为较短的片段

- 大型基因组（如小麦）有长的单一染色体，这些长度超过某些软件或文件格式的支持范围。
- `.bai`（BAM 索引文件）仅支持长度不超过 $2^{29}-1$ bp 的染色体。
- `.csi` 扩展了限制到 $2^{44}-1$ bp，但并不是所有软件都支持 .csi 格式。
- `.tbi`（变异索引文件）有相同的限制，且扩展的 `.csi` 格式在某些软件（如 GATK）中不被支持。

## 总结

本脚本功能；
1. 将基因组序列（FASTA 格式）分割成较小的片段。
2. 分割点总是位于 GAP 序列（一定长度的 N）。
3. GTF/GFF 的染色体名称和坐标可以同时转换对应。(可选项)

## 使用方法
### 安装

1. 下载[最新仓库代码](https://github.com/biomarble/splitLargeGenome/archive/refs/heads/main.zip)
2. 解压 `unzip splitLargeGenome-main.zip`
3. 运行：
```sh
perl splitLargeGenome-main/splitLargeGenome.pl
```

### 选项
```php
    -fa        <file>      必选       输入基因组序列文件，FASTA 格式
    -gxf       <file>      可选       对应 FASTA 文件的 GTF/GFF 文件，可选项
    -out       <str>       必选       输出文件前缀
    -numN      <num>       可选       作为分隔符的最小 N 长度，默认 10
    -minlen    <num>       可选       输出片段的最小长度，默认 300000000
    -maxlen    <num>       可选       输出片段的最大长度，默认 500000000
```

### 使用示例

- 完整用法

将一个基因组按照至少10个N为分隔符，分隔为300M~500M长度的小片段，同时将对应的gene.gtf修改为对应坐标。
```sh
perl splitLargeGenome.pl -fa genome.fa -minlen 300000000 -maxlen 500000000 -gxf gene.gtf -out genome.sep  -numN 10
```

- 只分割基因组

```sh
perl splitLargeGenome.pl -fa genome.fa -minlen 300000000 -maxlen 500000000 -out genome.sep  -numN 10
```

### 结果文件
```yaml

genome.sep.fa         : 长度在 300Mb 至 500Mb 之间的片段序列
genome.sep.detail.txt : 分割位置详细信息
gene.sep.gtf          : 按照详细信息调整位置的新 GTF 文件
                         只有在设置 -gxf 选项时才存在
```

## 报告问题

如有任何问题或建议可以：

- [提issue](https://github.com/biomarble/splitLargeGenome/issues) 
- [给我发邮件](mailto:biomarble@163.com)

