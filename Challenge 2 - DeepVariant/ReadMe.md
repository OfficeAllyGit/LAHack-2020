# DeepVariant Challenge
Google Deepvariant is an open source project which parses genomic data, and identifies "markers" (Single Nucleotide Polymorphisms).  In simple terms, these DNA markers help identify risk of certain diseases in patients.  Office Ally would like to enlist hackers' help with setting up the DeepVariant, and then using the sample files provided on google's web page to run against a list of possible hypertension markers.  Ultimately, we are looking for the following:

1.  A successful setup of Google Deepvariant using docker, following the steps on the GitHub page.
2.  A successful run of the sample files listed in Office Ally's github page (they are links to sample genomic files provided by Google) and compared against the data in the hypertension journal PDF.  How many hypertension markers were identified?
3.  Once steps 1 and 2 are achieved, a discussion on the CPU, memory, storage resources used to perform this analysis, and the length of time it took to complete given the resources.  What are some ways to make this run faster?

To be considered eligible for the prize, your solution must complete at least 1 and 2 above.

## Steps
In order to complete this, please perform the following steps:

1. Pull down the DeepVariant source code and set up DeepVariant on your machine:

    https://github.com/google/deepvariant/
    
   NOTE:  Do not use the google cloud or other paid versions!  We are looking at the local installation version only with Docker.

2. Read the case study here and perform the same actions step by step:

    https://github.com/google/deepvariant/blob/r0.9/docs/deepvariant-case-study.md

    In the example here you see the data files provided in storage.googleapis.com:

    https://github.com/google/deepvariant/blob/r0.9/scripts/run_wgs_case_study_docker.sh

3. Once you have completed these steps above (which includes setting up Docker and proving it works), use the Journal for hypertension PDF provided - "gwas htn2 Hypertension Journal.pdf".
4. Enter the hypertension values into a file or database; you will need to decide which format works best for the DeepVariant analysis in the next step.
5. Run DeepVariant against the SNVs in the journal, using the file or database you set up in #4, to see if there are any matches found by deepvariant with the journal.  Basically, you have identified whether the patient(s) in the vcf provided by google has hypertension.
