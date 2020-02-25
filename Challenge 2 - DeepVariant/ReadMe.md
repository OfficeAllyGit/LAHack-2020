Challenge:  Set up, install Deep Variant, and use its identified SNVs to find a match for hypertension in the journal.

In order to complete this, you should perform the following Steps:

1.  Clone or download the deepvariant source code: 
    https://github.com/google/deepvariant/
    
2.  Read the case study here and perform the same actions step by step:
    https://github.com/google/deepvariant/blob/r0.9/docs/deepvariant-case-study.md
    
    In the example here you see the data files provided in storage.googleapis.com:
    https://github.com/google/deepvariant/blob/r0.9/scripts/run_wgs_case_study_docker.sh
    
3.  Once you have completed these steps above (these involve set up of Docker and proving it works), use the Journal for hypertension PDF provided.

4.  Input the values of hypertension into "metadata" which can be utilized by deep variant.  This could be a file or database.  You need to decide what format works for deepvariant to do the compare.

5.  Run deep variant against the SNVs in the journal to see if there are any matches found by deepvariant with the journal.  Basically, you have identified whether the patient(s) in the vcf provided by google has hypertension.
