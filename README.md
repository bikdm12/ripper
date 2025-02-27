# Modified RIPPER
This is a modified version of the original [RIPPER](https://github.com/streptomyces/ripper).
It has two additional features: 

* it can process locally stored genomic GenBank files instead of downloading them from NCBI.
* it uses both TIGRFAMs and Pfam databases to annotate proteins encoded within genomic regions of interest

## Usage
By default, genomic files are downloaded from NCBI (just as in the original RIPPER). To process the locally stored files you need to make a subdirectory `gbkcache` with genomic files within the directory in which you are going to run the RIPPER (that becomes `/home/mnt/` after mounting the container).
Genbank files must be named with query protein accsession number and bear an extension `.gbk`. Example: 

`gbk_dir/WP_020387003.1.gbk`

This version always uses both Pfam and TIGRFAMs databases.

# RiPPER Overview

RiPPER (RiPP Precursor Peptide Enhanced Recognition) is a customisable tool for the identification of genes encoding putative precursor peptides within RiPP (ribosomally synthesised and post-translationally modified peptide) gene clusters. RiPPER carries out the following things to do this:

(1) Protein accession numbers for putative RiPP tailoring enzymes are used to retrieve gene clusters using [RODEO2](https://github.com/thedamlab/rodeo2)
(2) These are then searched for likely precursor peptide coding regions using both a modified form of [Prodigal](https://github.com/hyattpd/Prodigal) (prodigal-short) and a HMM-based search for precursor peptides.
(3) A Genbank file that highlights newly annotated short genes in the gene cluster is generated for visualisation in [Artemis](http://www.sanger.ac.uk/science/tools/artemis)
(4) Top-scoring peptides are tabulated alongside associated attribute data from a batch input for further analysis, and a fasta file is provided for peptide network analysis using [EGN](http://evol-net.fr/index.php/en/downloads)

We recommend that users work with a [Docker container of RiPPER](https://hub.docker.com/r/streptomyces/ripdock/). This is built from the latest version of RiPPER and includes all dependencies, so nothing needs installing apart from Docker and the RiPPER container. Details are provided below on using this in the **Docker** section, and a detailed technical description of the workflow is provided at the end of this page as **Description of RiPPER workflow**.

# Installation and usage

## Dependencies

1. Perl >= 5.14.0
2. BioPerl modules installed for the Perl being used.
3. Python >= 2.7.0
4. Biopython modules installed for the Python being used.
5. Perl modules _DBI_ and _DBD::SQLite_.
6. [HMMER](http://hmmer.org/).
7. [Prodigal](https://github.com/hyattpd/Prodigal). We actually use
a specially built form of Prodigal which we call _prodigal-short_.
The building of _prodigal-short_ is described later under the section
**Building prodigal-short**.

## Input file

The input for RiPPER is a .txt file that contains a list of NCBI accession numbers for proteins (one on each line) that the user wants to investigate for the presence of associated precursor peptide genes. Lists can be generated manually, or via multiple routes to retrieving a list of associated protein accessions, such as a BLAST search or [conserved domain retrieval]( https://www.ncbi.nlm.nih.gov/Structure/lexington/lexington.cgi).

## Docker

The simplest way to work with RiPPER is to use the Docker container, which includes all dependencies and can be run on Linux/MacOSX/Windows. This all follows installation of [Docker]( https://www.docker.com/get-started). 

### Pulling and running a RiPPER container

To install RiPPER:

~~~ {.sh}
docker pull streptomyces/ripdock
~~~

The default is to pull the image tagged as *latest*. You could pull a different image if you have a tag name. See example below where *testing* is the tag name:

~~~ {.sh}
docker pull streptomyces/ripdock:testing
~~~

Following installation, run the container using the following command, where
your input accession list file is stored in `/home/tom/rippwork` on Linux and
MacOS systems or `C:/Users/tom/rippwork` on a MS Windows system. (substitute your
relevant directories in place of these):

~~~ {.sh}
# Example usage on Linux
docker run -it -v /home/tom/rippwork:/home/mnt streptomyces/ripdock

# Example usage on MS Windows.
docker run -it -v C:/Users/tom/rippwork:/home/mnt streptomyces/ripdock
~~~

Do not change the `/home/mnt` part. This refers to a directory in the container and scripts in the container expect to find this directory. The host directory you mount on `/home/mnt` in the container is where the output directories and files are written to. You can place your input list in the mounted host directory on the host side and access it in /home/mnt/ on the container side. See the example **Run on your own list** below.

### Carrying out an analysis in the running container

Following the docker run command above, to ensure RiPPER is working correctly, you can run a small test analysis on 3 accessions that are included in a test file named *minitest.txt*. Use the following command:

~~~ {.sh}
./ripper_run.sh
~~~

#### Run on your own list

Use the following command to analyse your own list, substituting in a relevant filename for *te_accessions.txt*:

~~~ {.sh}
./ripper_run.sh /home/mnt/te_accessions.txt
~~~

## Analysis parameters

Peptide scoring and retrieval relies on a number of parameters that can be modified and are defined in a configuration file (local.conf, see **Description of RiPPER workflow** for more details). By default, settings that worked well during testing across multiple RiPP classes are used:

~~~ {.sh}
flankLen                17500
minPPlen                   20
maxPPlen                  120
maxDistFromTE            8000
sameStrandReward            5
fastaOutputLimit            3
prodigalScoreThresh        7.5
~~~

*flankLen* refers to the size of the nucleotide region retrieved from either side of the search protein.

*minPPlen* and *maxPPlen* refer to the minimum and maximum length of peptide (AA length) that will be searched for and retrieved by RiPPER.

*maxDistFromTE* refers to the maximum distance from the search protein (the tailoring enzyme, TE) that will be considered for peptide retrieval. Short genes will be annotated on the Genbank file outside of this region, but not tabulated.

*sameStrandReward* refers to a score boost if the peptide is encoded on the same strand as the tailoring enzyme.

*fastaOutputLimit* refers to the number of peptides retrieved for analysis from the maxDistFromTE region. Peptides are chosen for retrieval according to their Prodigal score, and there is no lower limit.  

*prodigalScoreThresh* is the score threshold where RiPPER will retrieve additional peptides if they are above this score and within the maxDistFromTE region.

### Modification of analysis parameters

Currently, *local.conf* needs to be directly modified to change the above parameters, although a future update will allow for parameters to be directly set in the command line. If Docker is used, the *local.conf* file is automatically present in the RiPPER container with the above defaults. To modify this, once the container is running, copy it into the host directory on your computer:

~~~ {.sh}
cp local.conf /home/mnt
~~~

Modify and save the file using a text editor and then use the following command to copy it back into the working directory for RiPPER:

~~~ {.sh}
cp /home/mnt/local.conf /home/work
~~~

## Output files

The RiPPER output consists of a series of output files and folders:

#### orgnamegbk
A folder containing Genbank files for all retrieved gene clusters. These files are named by the host organism and the input accession number

#### out.txt
This is a tab-delimited file that reports peptide data for all peptides retrieved by RiPPER (as defined by the analysis parameters above) for all gene clusters. This includes various associated data for the peptides, including Pfam domains and distance from the TE.

#### distant.txt
This is a tab-delimited file that reports peptide data for all peptides retrieved by RiPPER via a precursor peptide HMM search across the full size of the retrieved gene cluster (i.e. ignores maxDistFromTE), and only reports peptides that were not identified in the original RiPPER search. Peptide identifiers are unique from *out.txt*, so these text files can be combined for downstream analysis.

#### out.faa
A fasta file for peptides reported in out.txt that is formatted as an input file for similarity networking using [EGN]( http://evol-net.fr/index.php/en/downloads). An equivalent *distant.faa* is also provided.

#### rodeohtml
A folder containing RODEO html output files for all retrieved gene clusters. Additional RODEO data is provided in a separate **rodout** folder


# Description of RiPPER workflow

A bash script (ripper_run.sh, further details below) runs a series of
scripts to provide a full RiPPER analysis. This uses analysis settings
defined in an associated configuration file (local.conf). Where
relevant, variables defined in local.conf are described below.

Using an accession number for a predicted RiPP tailoring enzyme, the
[rodeo2](https://github.com/thedamlab/rodeo2) Python script
*rodeo\_main.py* produces and output file named *main\_co\_occur.csv*
that contains information about the annotated genes that flank the
RiPP tailoring enzyme.

*ripper.pl* reads the *main\_co\_occur.csv* file produced by
the *rodeo2* script *rodeo\_main.py* to determine the genbank
accession to fetch and the coordinats of the tailoring enzyme that was
used as the search term.

The genbank file is then fetched from GenBank and a smaller genbank
file is generated from it whose length is twice the value of the
variable *$flankLen* (default = 17500). This smaller genbank file,
hereafter referred to as the *sub-genbank* file, is centered around
the centre of the tailoring enzyme.

1. Determines the genbank accession to fetch based on the
value in column 3.

2. Determines the coordinates of the tailoring enzyme by reading
columns 5, 6 and 7 for the line in which the values in column 1 and
column 4 are identical.

Then the genbank file is fetched from Genbank and a smaller genbank
file is generated from it whose length is twice the value of the
variable *$flankLen*. This smaller genbank file, hereafter referred
to as the *sub-genbank* file, is centered around the centre of the
tailoring enzyme.

Rodeo retrieves the entire genbank file as it exists in Genbank.

A specially built version of *prodigal* renamed *prodigal-short* is
then used to find genes in the sub-genbank file. *prodigal-short* is
configured to find genes as short as 60 nucleotides compared to 90
nucleotides in the default build.

For all the genes found by *prodigal-short* the following is done.

1. The prodigal score is enhanced by a reward if the gene is on the
same strand as the tailoring enzyme and its score before reward is 
more than negative of the reward number.(variable `$sameStrandReward`,
default = 5).

2. Determine overlap with already annotated genes.

3. Translate to get the protein sequence.

4. If the length of the protein is less than `$minPPlen` (default = 20)
or greater than `$maxPPlen`; skip to the next gene found by prodigal.

5. If the gene has significant overlap (> 20 nucleotides) with an
already annotated gene then it is skipped.

6. If a gene is not filtered out in steps 4 or 5, it is annotated in
the genbank file and its distance from the tailoring enzyme is
determined.

7. If the gene is within a specified distance from the TE
(variable `$maxDistFromTE`, default = 8000)
it is included in the list to be output and also saved in a *Sqlite3*
table. By default, ripper.pl includes 3 peptides per gene cluster
(variable `$fastaOutputLimit`) within this specified distance, as well
as any additional peptides whose prodigal-short scores are greater
than variable `$prodigalScoreThresh` (default = 7.5).


The proteins in this table are then searched for pfam domains using
the *pfam\_sqlite.pl* script. The results of these searches are placed
in a new table in the same sqlite3 database.

*mergeRidePfam.pl* then merges the information contained in the two
sqlite3 tables, one containing the output of prodigal-short and the
other containing the output of Pfam searches on the proteins selected
from the output of prodigal-short. A tab delimited file (out.txt) is
then generated that contains all protein sequence and Pfam information
alongside various associated data (tailoring enzyme accession, strain,
peptide sequence, distance from tailoring enzyme, coding strand in
relation to tailoring gene, Prodigal score). If multiple genomic
regions are searched in parallel, all data are collated in this single
file.

*gbkNameAppendOrg.pl* copies the output genbank files to a new
directory with the organism names appended to the filenames for ease
of identification. Files are copied to the directory specified in the
configuration variable *orgnamegbkdir* (default = orgnamegbk).

*collectFiles.pl* is used to copy all rodeo result .html files into a
single directory defined by the *rodeohtmldir* variable in the
configuration file (default = rodeohtml).

### The Bash script implementing the full analysis pipeline

A file named *ripper\_run.sh* is included. If it is run without any
arguments it reads the file *minitest.txt* as input. You can supply a
different input file an argument to *ripper\_run.sh*.

The starting point is a query file containing Genpept accessions for
tailoring enzymes. In the example below this file is named
*minitest.txt*. The input file should contain a list of tailoring
enzyme accessions.

Contents of *ripper_run.sh* are listed below. There is no need to make
any changes to it.

~~~ {.sh}
#!/bin/bash
# This file is the bash script that provides a full RiPPER analysis
# that encompasses a number of related Perl scripts. Final outputs
# are found in orgnamegbk (GenBank files featuring RiPPER annotations),
# out.txt (tab-delimited table containing retrieved peptides and
# associated data) and rodeohtml (RODEO2 html output).
# This file should be in the directory from where it
# will be run. The local.conf file (featuring any parameter
# modifications) should also be placed in this directory
# This file should be in the directory from where it
# will be run as
#
#  ./ripper_run.sh <inputfilename>
#
#

# Query file name defaults to minitest.txt.
queryfn=$1;

if [[ ${#queryfn} -lt 1 ]]; then
  queryfn="minitest.txt";
fi

if [[ ! -s ${queryfn} || ! -e ${queryfn} ]]; then
echo "Either $queryfn does not exists or is zero in size. Aborting."; 
exit 1;
fi


ripperdir=/home/work/ripper;
rodeodir=/home/work/rodeo2;
pfamdir=/home/work/pfam



# Tab delimited output file for results including pfam hits.
outfile=/home/mnt/out.txt

# Rodeo output directory
rodoutdir=/home/mnt/rodout;

# ripper output directory. Contains gbk files.
ripoutdir=/home/mnt/ripout;

# ripper output directory. Contains gbk files where filenames
# have the organism name prepended for convenience. 
orgnamegbkdir=/home/mnt/orgnamegbk;

# The html file output by rodeo2 are here.
rodeohtmldir=/home/mnt/rodeohtml;

# Below is legacy from the Linux installable version of this script.

perlbin="perl"
pythonbin="python"


# Make a couple of symlinks to keep rodeo_main.py happy.
ln -s $pfamdir ./hmm_dir
ln -s ${rodeodir}/confs ./

# Make the various directories where output will be placed.
for hcd in $rodoutdir $ripoutdir sqlite gbkcache $orgnamegbkdir $rodeohtmldir; do
if [[ ! -d $hcd ]]; then
  mkdir $hcd
fi
done

### Setup is now complete. Actual runs below. ###

# rodeo run and ripper.pl run for each query in $queryfn

for acc in $(cat $queryfn); do 
  echo $pythonbin ${rodeodir}/rodeo_main.py -out ${rodoutdir}/${acc} ${acc}
  $pythonbin ${rodeodir}/rodeo_main.py -out ${rodoutdir}/${acc} ${acc}
  echo $perlbin ${ripperdir}/ripper.pl -outdir $ripoutdir -- ${rodoutdir}/${acc}/main_co_occur.csv
  $perlbin ${ripperdir}/ripper.pl -outdir $ripoutdir -- ${rodoutdir}/${acc}/main_co_occur.csv
done

# Run the postprocessing scripts

$perlbin ${ripperdir}/pfam_sqlite.pl
$perlbin ${ripperdir}/mergeRidePfam.pl -out ${outfile}
$perlbin ${ripperdir}/gbkNameAppendOrg.pl -indir $ripoutdir
$perlbin ${ripperdir}/collectFiles.pl ${rodoutdir} ${rodeohtmldir} '\.html$'
~~~

### Example of *local.conf*

A file named *local.conf* is included in the repository.

*local.conf* is a two column (space delimited) text file which is read
by *ripper.pl* and the postprocessing scripts in the pipeline. There
should be no need to make changes to this file unless default parameters are being changed (as described above).

~~~ 
# Lines beginning with # are comments.
# All names are case sensitive.

# Downloaded genbank files are cached here.
# ripper_run.sh automatically generates a gbkcache
# directory in the directory it is run from.
gbkcache            gbkcache

# Filename for the SQLite3 database.
# ripper_run.sh automatically generates a sqlite
# directory in the directory it is run from.
sqlite3fn           sqlite/ripp.sqlite3

# Location of prodigal-short binary
# prodigalshortbin          /usr/local/bin/prodigal-short

# Location of hmmscan binary
# hmmscanbin          /usr/local/bin/hmmscan

# Directory containing the Pfam database files.
# Should be the same as pfamdir in the ripper_run.sh file.
hmmdir              pfam

# Name of the Pfam database to use.
hmmdb               Pfam-A.hmm

# Name of the Pfam data file.
# Used for reading information about models.
pfamhmmdatfn        Pfam-A.hmm.dat

# Name of the SQLite3 table where results of
# hmmer searches are stored.
pfamrestab          pfamscan

# Name of the SQLite3 table where results of
# prodigal search are stored.
prepeptab           ripper

# Directory where output genbank files are stored.
# Organism names are prefixed to the file names for
# ease of identification.
# ripper_run.sh automatically generates an orgnamegbk directory in the
# directory it is run from.
orgnamegbkdir       /home/mnt/orgnamegbk

# Below are some defaults (commented out) that can also
# be specified in this file by removing the hashtag.
# The names are case sensitive!

# minPPlen                   20
# maxPPlen                  120
# prodigalScoreThresh        7.5
# maxDistFromTE            8000
# fastaOutputLimit            3
# sameStrandReward            5
# flankLen                17500
~~~

### Building *prodigal-short*

This is for documentation only. *prodigal-short* is provided in the
Docker version.

The following changes (shown as the output of the *git diff* command)
were made to *prodigal* source files before building
*prodigal-short* according to instructions provided with the
*prodigal* source download.

1. In the file *makefile* first and only occurrence of
`TARGET = prodigal` was changed to `TARGET = prodigal-short`.

~~~ {.diff}
diff --git a/Makefile b/Makefile
index 23ffe00..6edbb53 100644
--- a/Makefile
+++ b/Makefile
@@ -24,7 +24,7 @@ CC      = gcc
 CFLAGS  += -pedantic -Wall -O3
 LFLAGS = -lm $(LDFLAGS)

-TARGET  = prodigal
+TARGET  = prodigal-short
 SOURCES = $(shell echo *.c)
 HEADERS = $(shell echo *.h)
 OBJECTS = $(SOURCES:.c=.o)
~~~

2. In the file *dprog.h* first and only occurrence of
`#define MAX_SAM_OVLP 60` was changed to `#define MAX_SAM_OVLP 45`

~~~ {.diff}
diff --git a/dprog.h b/dprog.h
index d729f4c..ea7fa10 100644
--- a/dprog.h
+++ b/dprog.h
@@ -26,7 +26,7 @@
 #include "sequence.h"
 #include "node.h"

-#define MAX_SAM_OVLP 60
+#define MAX_SAM_OVLP 45
 #define MAX_OPP_OVLP 200
 #define MAX_NODE_DIST 500
~~~

3. In the file *node.h* the following lines

~~~ {.diff}
#define MIN_GENE 90
#define MIN_EDGE_GENE 60
#define MAX_SAM_OVLP 60
#define ST_WINDOW 60
#define OPER_DIST 60
~~~

Were changed to the following lines.

~~~ {.diff}
#define MIN_GENE 60
#define MIN_EDGE_GENE 45
#define MAX_SAM_OVLP 45
#define ST_WINDOW 45
#define OPER_DIST 45
~~~

~~~ {.diff}
diff --git a/node.h b/node.h
index 6c722be..551c7b8 100644
--- a/node.h
+++ b/node.h
@@ -27,11 +27,11 @@
 #include "training.h"

 #define STT_NOD 100000
-#define MIN_GENE 90
-#define MIN_EDGE_GENE 60
-#define MAX_SAM_OVLP 60
-#define ST_WINDOW 60
-#define OPER_DIST 60
+#define MIN_GENE 60
+#define MIN_EDGE_GENE 45
+#define MAX_SAM_OVLP 45
+#define ST_WINDOW 45
+#define OPER_DIST 45
 #define EDGE_BONUS 0.74
 #define EDGE_UPS -1.00
 #define META_PEN 7.5
~~~


### Other supporting Perl scripts

#### pfam\_sqlite.pl

*pfam\_sqlite.pl* takes all the proteins in a specified table in a
specified sqlite3 database and searches them for Pfam domains. The
results of these searches are placed in a new table in the same
sqlite3 database.

#### mergeRidePfam.pl

*mergeRidePfam.pl* merges the information contained in the two sqlite3
tables, one containing the output of prodigal-short and the other
containing the output of Pfam searches on the proteins selected from
the output of prodigal-short. It writes out a tab delimited file.

#### gbkNameAppendOrg.pl

Copies the output genbank files to a new directory with the organism
names appended to the filenames for ease of identification. Files are
copied to the directory specified in the configuration variable
*orgnamegbkdir*.

#### collectFiles.pl

*collectFiles.pl* copies files from a specified directory (and
subdirectories) to another directory if the base filename matches the
specified regular expression.

~~~ {.sh}
perl collectFiles.pl -indir rodout -pat '\.html$' -outdir rodeohtml
~~~

The options shown above are the defaults. *-outdir* may be specified
in *local.conf* as *rodeohtmldir*. Value in the configuration file
takes precedence.
