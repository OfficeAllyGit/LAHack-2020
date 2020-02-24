/*  DISCLAIMER 
	 2020 Copyright Office Ally, Inc
	 This code may not be redistributed for any other purpose, besides for the 2020 Hackathon research.
	 This code is a proof of concept and is still in development.  It is not guaranteed to work completely in its current form.
	 The target audience who receives this code should be limited to only participants at the 2020 hackathon.  Anyone who obtains this and do not meet what is described here will be legally liable.
	 Office Ally reserves the right to persecute any entity who steals or applies this intellectual property without Office Ally's Consent.
	--End Disclaimer 
*/
--// Testing confidence rating
USE DataExport


DECLARE	@OASALT VARCHAR(25)
    
SELECT
	@OASALT = 'OATEST'
  
IF OBJECT_ID('tempdb..#tmpHASH') IS NOT NULL
	DROP TABLE #tmpHASH;
WITH	cteImport
		  AS (
			  SELECT DISTINCT TOP 10000
				P.LAST_NAME LastName
			  , P.FIRST_NAME FirstName
			  , P.GENDER
			  , P.DATE_OF_BIRTH DateOfBirth
			  FROM
				OfficeAlly_SS.dbo.PATIENTS P
			 ) ,
		cteHASH
		  AS (
			  SELECT
				X.idx
			  , X.Gender
			  , DateOfBirth
			  , (HASHBYTES('SHA1',
						   (@OASALT + (CONVERT([CHAR](8), [DateOfBirth], (112)) + '~' + [Gender]) + '~' + [FirstName])
						   + '~' + [LastName])) [FullNameHash]
			  , (HASHBYTES('SHA1',
						   (@OASALT + (CONVERT([CHAR](8), [DateOfBirth], (112)) + '~' + [Gender]) + '~'
							+ LEFT([FirstName] + 'XXX', (3))) + '~' + LEFT([LastName] + 'XXX', (3)))) [ParHash]
			  , orgLastName
			  , orgFirstName
			  FROM
				(
				 SELECT
					ROW_NUMBER() OVER (ORDER BY C.LastName) idx
				  , CONVERT(DATETIME, DateOfBirth) [DateOfBirth]
				  , UPPER(ISNULL(CONVERT(CHAR(1), GENDER), 'U')) [Gender]
				  , UPPER(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), FirstName))) [FirstName]
				  , UPPER(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), LastName))) [LastName]
				  , C.LastName orgLastName
				  , C.FirstName orgFirstName
		  --, '' MiddleName
				 FROM
					cteImport C
				) X
			 ) ,
		cteHIDX
		  AS (
			  SELECT
				CH.idx
			  , ROW_NUMBER() OVER (ORDER BY CH.ParHash) hashID
			  , CH.ParHash
			  FROM
				cteHASH CH
			 )
	SELECT
		C.idx
	  , C.hashID
	  , TH.ParHash
	  , 'AP' + RIGHT('00000000' + CONVERT(VARCHAR(10), 100 + C.hashID), 8) xRefID
	  , DATEADD(DAY, (CASE WHEN FLOOR((RAND() * 2) + 1) = 1 THEN -1
						   ELSE 1
					  END) * FLOOR(RAND() * (60) + 1), TH.DateOfBirth) NewDateOfBirth
	  , TH.Gender
	  , TH.orgLastName
	  , TH.orgFirstName
	INTO
		#tmpHash
	FROM
		cteHASH TH
		JOIN cteHIDX C ON C.idx = TH.idx
	ORDER BY
		TH.idx


IF OBJECT_ID('tempdb..#tmpMatch') IS NOT NULL
	DROP TABLE #tmpMatch
	
--// we can only tolerate unique claimIDs, so duplicate patients need to be excluded
;
WITH	cte
		  AS (
			  SELECT
				MIN(TAAPT.idx) idx
			  , TAAPT.hashID
			  , TAAPT.ParHash
			  FROM
				#tmpHash TAAPT
			  WHERE
				TAAPT.ParHash IS NOT NULL
			  GROUP BY
				TAAPT.hashID
			  , TAAPT.ParHash
			 )
	SELECT TOP 100 PERCENT
		c.idx
	  , c.hashID
	  , c.ParHash
	  , PHH.ClaimID
	INTO
		#tmpMatch
	FROM
		cte c
		JOIN OADWH_HASH.dbo.vPatientHash_HCFA PHH WITH (NOLOCK) ON PHH.ParHash = c.ParHash
	
	
IF OBJECT_ID('tempdb..#tmpStageName') IS NOT NULL
	DROP TABLE #tmpStageName

SELECT
	TM.idx
  , TM.hashID
  , TM.ParHash
  , TM.ClaimID
  , TH.orgLastName srcLastName
  , TH.orgFirstName srcFirstName
  , P.LAST_NAME fndLastName
  , P.FIRST_NAME fndFirstName
  , OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TH.orgLastName)) srcRnaLastName
  , OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TH.orgFirstName)) srcRnaFirstName
  , OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.LAST_NAME)) fndRnaLastName
  , OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.FIRST_NAME)) fndRnaFirstName
INTO
	#tmpStageName
FROM
	#tmpMatch TM
	JOIN #tmpHash TH ON TH.idx = TM.idx
	JOIN OfficeAlly_SS.dbo.HCFA1500 H ON H.HCFA1500_ID = TM.ClaimID
	JOIN OfficeAlly_SS.dbo.PATIENTS P ON P.PATIENT_ID = H.PATIENT_ID
WHERE
	1 = 1	

IF OBJECT_ID('tempdb..#tmpReview') IS NOT NULL
	DROP TABLE #tmpReview

SELECT
	TSN.idx
  , TSN.hashID
  , TSN.ParHash
  , TSN.ClaimID
	  --// 
  , TSN.srcLastName
  , TSN.srcFirstName
  , TSN.srcRnaLastName
  , TSN.srcRnaFirstName
  , TSN.fndRnaLastName
  , TSN.fndRnaFirstName
  , TSN.fndLastName
  , TSN.fndFirstName
	  --// 
  , CASE WHEN TSN.srcRnaLastName = TSN.fndRnaLastName
			  AND TSN.srcRnaFirstName = TSN.fndRnaFirstName THEN 100
		 WHEN TSN.srcRnaLastName = TSN.fndRnaLastName
			  AND LEFT(TSN.srcRnaFirstName, 4) = LEFT(TSN.fndRnaFirstName, 4) THEN 90
			--//----
		 WHEN TSN.srcRnaLastName = TSN.fndRnaLastName THEN 85
			--//---
		 WHEN LEFT(TSN.srcRnaLastName, 5) = LEFT(TSN.fndRnaLastName, 5)
			  AND LEFT(TSN.srcRnaFirstName, 4) = LEFT(TSN.fndRnaFirstName, 4) THEN 80
		 WHEN SOUNDEX(TSN.srcLastName) = SOUNDEX(TSN.fndLastName)
			  AND SOUNDEX(TSN.srcFirstName) = SOUNDEX(TSN.fndFirstName) THEN 79
		 WHEN SOUNDEX(TSN.srcRnaLastName) = SOUNDEX(TSN.fndRnaLastName)
			  AND SOUNDEX(TSN.srcRnaFirstName) = SOUNDEX(TSN.fndRnaFirstName) THEN 77
		 WHEN LEFT(TSN.srcRnaLastName, 4) = LEFT(TSN.fndRnaLastName, 4)
			  AND TSN.srcRnaFirstName = TSN.fndRnaFirstName THEN 76
		 WHEN TSN.srcRnaFirstName = TSN.fndRnaFirstName THEN 60
		 ELSE 50
	END Confidence
INTO
	#tmpReview
FROM
	#tmpStageName TSN
	
IF OBJECT_ID('tempdb..#tmpSummary') IS NOT NULL DROP TABLE #tmpSummary	
	

			  SELECT
				hashID
			  , COUNT(DISTINCT ClaimID) #Claims
			  , srcLastName
			  , srcFirstName
			  , srcRnaLastName
			  , srcRnaFirstName
			  , fndRnaLastName
			  , fndRnaFirstName
			  , fndLastName
			  , fndFirstName
			  , Confidence
			  INTO #tmpSummary
			  FROM
				#tmpReview
			  GROUP BY
				hashID
			  , srcLastName
			  , srcFirstName
			  , srcRnaLastName
			  , srcRnaFirstName
			  , fndRnaLastName
			  , fndRnaFirstName
			  , fndLastName
			  , fndFirstName
			  , Confidence
			 
	SELECT
		*
	FROM
		#tmpSummary
	WHERE
		Confidence = 76


SELECT
	COUNT(DISTINCT hashID) #Hash
  , Confidence
FROM
	#tmpSummary
GROUP BY
	Confidence
ORDER BY
	Confidence DESC
	

RETURN 


IF OBJECT_ID('tempdb..#tmpReview') IS NOT NULL
	DROP TABLE #tmpReview
	

SELECT
	COUNT(DISTINCT TM.idx) #Occurrence
  , TM.hashID
  , TM.ParHash
  , COUNT(DISTINCT TM.ClaimID) #Claims
  , TAAPI.idx
  , TAAPI.orgLastName
  , TAAPI.orgFirstName
  , '~' [~]
  , P.LAST_NAME
  , P.FIRST_NAME
  , P.DATE_OF_BIRTH
  , CASE WHEN OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgLastName)) = OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.LAST_NAME))
			  AND OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgFirstName)) = OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.FIRST_NAME))
		 THEN 100
		 WHEN OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgLastName)) = OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.LAST_NAME))
			  AND LEFT(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgFirstName)), 4) = LEFT(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.FIRST_NAME)),
																										4) THEN 90
		 WHEN OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgLastName)) = OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.LAST_NAME))
			  AND SOUNDEX(orgFirstName) = SOUNDEX(FIRST_NAME) THEN 85
		 WHEN LEFT(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgLastName)), 5) = LEFT(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.LAST_NAME)),
																										5)
			  AND LEFT(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgFirstName)), 4) = LEFT(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.FIRST_NAME)),
																										4) THEN 80
		 WHEN SOUNDEX(orgLastName) = SOUNDEX(LAST_NAME)
			  AND SOUNDEX(orgFirstName) = SOUNDEX(FIRST_NAME) THEN 79
		 WHEN SOUNDEX(OADWH_HASH.dbo.RemoveNonAlphaNumeric(orgLastName)) = SOUNDEX(OADWH_HASH.dbo.RemoveNonAlphaNumeric(P.LAST_NAME))
			  AND SOUNDEX(OADWH_HASH.dbo.RemoveNonAlphaNumeric(orgFirstName)) = SOUNDEX(OADWH_HASH.dbo.RemoveNonAlphaNumeric(P.FIRST_NAME))
		 THEN 77
		 WHEN LEFT(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgLastName)), 4) = LEFT(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.LAST_NAME)),
																										4)
			  AND OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgFirstName)) = OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.FIRST_NAME))
		 THEN 76
		 WHEN OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgLastName)) = OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.LAST_NAME))
		 THEN 75
		 WHEN OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgFirstName)) = OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.FIRST_NAME))
		 THEN 60
		 ELSE 50
	END Confidence
INTO
	#tmpReview
FROM
	#tmpMatch TM
	JOIN #tmpHash TAAPI ON TAAPI.idx = TM.idx
	JOIN OfficeAlly_SS.dbo.HCFA1500 H ON H.HCFA1500_ID = TM.ClaimID
	JOIN OfficeAlly_SS.dbo.PATIENTS P ON P.PATIENT_ID = H.PATIENT_ID
WHERE
	1 = 1
	--AND  (
	--LEFT(UPPER(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgFirstName))) ,4) =LEFT(UPPER(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.FIRST_NAME))) ,4) 
	--AND LEFT(UPPER(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), TAAPI.orgLastName))) ,4) =LEFT(UPPER(OADWH_HASH.dbo.RemoveNonAlphaNumeric(CONVERT(VARCHAR(25), P.LAST_NAME))) ,4) 
	--)
GROUP BY
	TM.hashID
  , TM.ParHash
  , TAAPI.idx
  , TAAPI.orgLastName
  , TAAPI.orgFirstName
  , TAAPI.Gender
  , P.LAST_NAME
  , P.FIRST_NAME
  , P.DATE_OF_BIRTH
  , P.GENDER
ORDER BY
	Confidence
  , TM.hashID
  
  
  
  
SELECT
	#Occurrence
  , hashID
  , ParHash
  , #Claims
  , idx
  , orgLastName
  , orgFirstName
  , [~]
  , LAST_NAME
  , FIRST_NAME
  , DATE_OF_BIRTH
  , Confidence
  , '@' [@]
  , SOUNDEX(orgLastName) snd_orgLastName
  , SOUNDEX(LAST_NAME) snd_LAST_NAME
  , SOUNDEX(orgFirstName) snd_orgFirstName
  , SOUNDEX(FIRST_NAME) snd_FIRST_NAME
  , '#' [%]
  , DIFFERENCE(orgLastName, LAST_NAME) dif_LastName
  , DIFFERENCE(orgFirstName, FIRST_NAME) dif_FirstName
  , SOUNDEX(OADWH_HASH.dbo.RemoveNonAlphaNumeric(orgLastName)) sndn_orgLastName
  , SOUNDEX(OADWH_HASH.dbo.RemoveNonAlphaNumeric(orgFirstName)) sndn_orgFirstName
FROM
	#tmpReview
WHERE
	Confidence = 65
	
	
SELECT
	COUNT(DISTINCT hashID) #Hash
  , Confidence
FROM
	#tmpReview
GROUP BY
	Confidence
ORDER BY
	Confidence DESC
