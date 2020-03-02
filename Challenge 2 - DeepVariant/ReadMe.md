# DeepVariant Challenge
Set up, install DeepVariant, and use its identified SNVs to find a match for hypertension in the journal.

## Steps
In order to complete this, please perform the following steps:

1. Pull down the DeepVariant source code and set up DeepVariant on your machine:

    https://github.com/google/deepvariant/

2. Read the case study here and perform the same actions step by step:

    https://github.com/google/deepvariant/blob/r0.9/docs/deepvariant-case-study.md

    In the example here you see the data files provided in storage.googleapis.com:

    https://github.com/google/deepvariant/blob/r0.9/scripts/run_wgs_case_study_docker.sh

3. Once you have completed these steps above (which includes setting up Docker and proving it works), use the Journal for hypertension PDF provided - "gwas htn2 Hypertension Journal.pdf".
4. Enter the hypertension values into a file or database; you will need to decide which format works best for the DeepVariant analysis.
5. Run DeepVariant against the SNVs in the journal to see if there are any matches found by deepvariant with the journal.  Basically, you have identified whether the patient(s) in the vcf provided by google has hypertension.
