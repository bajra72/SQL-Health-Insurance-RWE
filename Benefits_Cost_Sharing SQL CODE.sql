-- Clean data and type conversion
ALTER TABLE "Benefits_Cost_Sharing" ADD COLUMN "CleanerImportDate" date;
UPDATE "Benefits_Cost_Sharing"
SET "CleanerImportDate" = strftime ('%Y-%m-%d', substr ("ImportDate", 1, instr ("ImportDate", ' ') - 1));

-- Add new columns for cleaned numerical cost-sharing data
ALTER TABLE "Benefits_Cost_Sharing" ADD COLUMN "CleanedCopayInnTier1" REAL;
ALTER TABLE "Benefits_Cost_Sharing" ADD COLUMN "CleanedCopayInnTier2" REAL;
ALTER TABLE "Benefits_Cost_Sharing" ADD COLUMN "CleanedCopayOutofNet" REAL;
ALTER TABLE "Benefits_Cost_Sharing" ADD COLUMN "CleanedCoinsInnTier1" REAL;
ALTER TABLE "Benefits_Cost_Sharing" ADD COLUMN "CleanedCoinsInnTier2" REAL;
ALTER TABLE "Benefits_Cost_Sharing" ADD COLUMN "CleanedCoinsOutofNet" REAL;
ALTER TABLE "Benefits_Cost_Sharing" ADD COLUMN "CleanedLimitQty" REAL;

-- Cleaning and populating new numerical cost-sharing columns
UPDATE "Benefits_Cost_Sharing"
SET
"CleanedCopayInnTier1" = 
CASE
WHEN "CopayInnTier1" = 'Not Applicable' THEN 0.0
ELSE CAST(replace(replace("CopayInnTier1", '$', ' '), ',', ' ')AS REAL)
END,
"CleanedCopayInnTier2" =
CASE
WHEN "CopayInnTier2" = 'Not Applicable' THEN 0.0
ELSE CAST(REPLACE(REPLACE("CopayInnTier2", '$', ''), ',', '') AS REAL)
END,
"CleanedCopayOutofNet" =
CASE
WHEN "CopayOutofNet" IS NULL OR TRIM("CopayOutofNet") IN ('', 'Not Applicable') THEN 0.0
WHEN INSTR("CopayOutofNet", '%') > 0 THEN NULL
ELSE CAST(REPLACE(REPLACE("CopayOutofNet", '$', ''), ',', '') AS REAL)
END,
"CleanedCoinsInnTier1" = CASE
WHEN "CoinsInnTier1" like '%Coinsurance after deductible%' THEN CAST(replace(replace("CoinsInnTier1", '% Coinsurance after deductible', ' '), ',', ' ') As REAL)/100.0
WHEN "CoinsInnTier1" LIKE '%Coinsurance%' THEN CAST(REPLACE(REPLACE("CoinsInnTier1", '% Coinsurance', ''), ',', '') AS REAL) / 100.0
WHEN "CoinsInnTier1" = 'Not Applicable' THEN 0.0
ELSE NULL
END,
"CleanedCoinsInnTier2" = CASE
WHEN "CoinsInnTier2" LIKE '%Coinsurance after deductible%' THEN CAST(REPLACE(REPLACE("CoinsInnTier2", '% Coinsurance after deductible', ''), ',', '') AS REAL) / 100.0
WHEN "CoinsInnTier2" LIKE '%Coinsurance%' THEN CAST(REPLACE(REPLACE("CoinsInnTier2", '% Coinsurance', ''), ',', '') AS REAL) / 100.0
WHEN "CoinsInnTier2" = 'Not Applicable' THEN 0.0
ELSE NULL
END,
"CleanedCoinsOutofNet" =
CASE
WHEN "CoinsOutofNet" IS NULL OR TRIM("CoinsOutofNet") IN ('', 'Not Applicable') THEN 0.0
WHEN "CoinsOutofNet" LIKE '%Coinsurance after deductible%' THEN CAST(REPLACE(REPLACE("CoinsOutofNet", '% Coinsurance after deductible', ''), ',', '') AS REAL) / 100.0
WHEN "CoinsOutofNet" LIKE '%Coinsurance%' THEN CAST(REPLACE(REPLACE("CoinsOutofNet", '% Coinsurance', ''), ',', '') AS REAL) / 100.0
ELSE NULL
END,
"CleanedLimitQty" =
CASE
WHEN "LimitQty" IS NULL OR "LimitQty" = '' THEN NULL
WHEN "LimitQty" = 'Unlimited' THEN 999999.0
ELSE CAST(REPLACE(REPLACE("LimitQty", ',', ''), '$', '') AS REAL)
END;
UPDATE "Benefits_Cost_Sharing"
SET "IsCovered" = upper(trim("IsCovered"));
UPDATE "Benefits_Cost_Sharing"
Set "IsCovered" =
CASE
WHEN "IsCovered" In ('Yes', 'Y', 'COVERED') THEN 'YES'
WHEN "IsCovered" In ('No', 'N', 'Not Covered') THEN 'NO'
ELSE 'UNKNOWN'
END;

-- Identify how many plans cover 'Routine Dental Services (Adult)' and how many do not
SELECT "IsCovered", COUNT(*) AS CountOfStatus
FROM "Benefits_Cost_Sharing"
WHERE "BenefitName" = 'Routine Dental Services (Adult)'
GROUP BY "IsCovered";

-- Identify the top 10 most common types of quantity limits applied to benefits
SELECT "LimitUnit", COUNT(*) AS COUNTOFUNIT
FROM "Benefits_Cost_Sharing"
WHERE "LimitUnit" IS NOT NULL AND "LimitUnit" !=' '
GROUP BY "LimitUnit"
ORDER BY COUNTOFUNIT DESC
LIMIT 10;

-- Calculate the average in-network (Tier 1 & 2) and out-of-network copayments specifically for drug-related benefits
SELECT
avg("CleanedCopayInnTier1") AS avgCOPAYTIER1,
avg("CleanedCopayInnTier2") AS avgCOPAYTIER2,
avg("CleanedCopayOutofNet") AS avgCOPAYOUTOFNET
FROM "Benefits_Cost_Sharing"
WHERE "BenefitName" like '%DRUG%';

-- Calculate the average in-network (Tier 1 & 2) and out-of-network coinsurance percentages for drug-related benefits
SELECT
AVG("CleanedCoinsInnTier1") AS AvgCoinsuranceTier1,
AVG("CleanedCoinsInnTier2") AS AvgCoinsuranceTier2, -- Add for all relevant tiers
AVG("CleanedCoinsOutofNet") AS AvgCoinsuranceOutofNet
FROM "Benefits_Cost_Sharing"
WHERE "BenefitName" LIKE '%Drug%';

-- Identify the top 10 states with the highest average in-network Tier 1 drug copays
SELECT
"StateCode",
AVG("CleanedCopayInnTier1") AS AvgTier1Copay
FROM "Benefits_Cost_Sharing"
WHERE "BenefitName" LIKE '%Drug%' AND "CleanedCopayInnTier1" IS NOT NULL
GROUP BY "StateCode"
ORDER BY AvgTier1Copay DESC
LIMIT 10;

-- Calculate the average Tier 1 drug copay within each tier after segmenting plans into deductible tiers
SELECT
CASE
WHEN "CleanedDrugDeductibleIndividual" = 0 THEN '0 Deductible'
WHEN "CleanedDrugDeductibleIndividual" > 0 AND "CleanedDrugDeductibleIndividual" <= 1000 THEN 'Low Deductible ($1-1000)'
WHEN "CleanedDrugDeductibleIndividual" > 1000 AND "CleanedDrugDeductibleIndividual" <= 5000 THEN 'Medium Deductible ($1001-5000)'
WHEN "CleanedDrugDeductibleIndividual" > 5000 THEN 'High Deductible (>$5000)'
ELSE 'No Deductible Data'
END AS DeductibleTier,
COUNT(*) AS NumberOfPlans,
AVG("CleanedCopayInnTier1") AS AvgTier1Copay,
AVG("CleanedCoinsInnTier1") AS AvgTier1Coinsurance
FROM "Benefits_Cost_Sharing"
WHERE "BenefitName" LIKE '%Drug%'
GROUP BY DeductibleTier
ORDER BY AvgTier1Copay DESC;

-- Identify the top 10 issuers with the highest average Tier 1 drug copays and coinsurance across their plans
SELECT
"IssuerId",
COUNT(*) AS NumberOfPlans,
AVG("CleanedCopayInnTier1") AS AvgTier1Copay,
AVG("CleanedCoinsInnTier1") AS AvgTier1Coinsurance,
AVG("CleanedDrugDeductibleIndividual") AS AvgDrugDeductible
FROM "Benefits_Cost_Sharing"
WHERE
"BenefitName" LIKE '%Drug%'
AND "CleanedCopayInnTier1" IS NOT NULL
AND "CleanedDrugDeductibleIndividual" IS NOT NULL
GROUP BY "IssuerId"
HAVING COUNT(*) > 50
ORDER BY AvgTier1Copay DESC
LIMIT 10;

-- Provide a full overview of a state's cost-sharing landscape
SELECT
"StateCode",
COUNT(*) AS NumberOfPlans,
AVG("CleanedCopayInnTier1") AS AvgTier1Copay,
AVG("CleanedCoinsInnTier1") AS AvgTier1Coinsurance,
AVG("CleanedDrugDeductibleIndividual") AS AvgDrugDeductible,
AVG("CleanedMaximumOutofPocketIndividual") AS AvgMOOPIndividual
FROM "Benefits_Cost_Sharing"
WHERE
"BenefitName" LIKE '%Drug%'
AND "CleanedCopayInnTier1" IS NOT NULL
AND "CleanedDrugDeductibleIndividual" IS NOT NULL
AND "CleanedMaximumOutofPocketIndividual" IS NOT NULL
GROUP BY "StateCode"
ORDER BY AvgTier1Copay DESC;