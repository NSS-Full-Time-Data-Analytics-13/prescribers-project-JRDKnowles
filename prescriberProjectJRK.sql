SELECT npi, COUNT(drug_name) AS drugs_prescribed
FROM prescription
LEFT JOIN prescriber USING (npi)
GROUP BY npi
ORDER BY COUNT(drug_name) DESC
LIMIT 1;
--1356305197

--    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, 
	--and the total number of claims.
SELECT npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, COUNT(drug_name) AS drugs_prescribed
FROM prescription
LEFT JOIN prescriber USING (npi)
GROUP BY prescriber.nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, npi
ORDER BY COUNT(drug_name) DESC
LIMIT 1;
--MICHAEL COX, Internal Medicine, 379 prescriptions

--2. 
   -- a. Which specialty had the most total number of claims (totaled over all drugs)?

   -- b. Which specialty had the most total number of claims for opioids?
SELECT COUNT(*), specialty_description
FROM prescriber
LEFT JOIN prescription USING (npi)
GROUP BY specialty_description
ORDER BY COUNT(*) DESC;
--Nurse Practitioner

SELECT specialty_description, COUNT(drug.opioid_drug_flag) AS opioid_claims
FROM prescriber
LEFT JOIN prescription USING (npi)
	LEFT JOIN drug USING (drug_name)
	WHERE opioid_drug_flag ILIKE 'Y'
GROUP BY specialty_description
ORDER BY COUNT(drug.opioid_drug_flag) DESC;
--Nurse Practitioner

-- c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
LEFT JOIN prescription USING (npi)
	LEFT JOIN drug USING (drug_name)
GROUP BY specialty_description
ORDER BY sum NULLS FIRST;
--"Specialist/Technologist, Other"
--"Chiropractic"
--"Physical Therapist in Private Practice"
--"Marriage & Family Therapist"
--"Midwife"
--"Physical Therapy Assistant"
--"Medical Genetics"
--"Occupational Therapist in Private Practice"
--"Licensed Practical Nurse"
--"Hospital"
--"Undefined Physician type"
--"Ambulatory Surgical Center"
--"Radiology Practitioner Assistant"
--"Developmental Therapist"
--"Contractor"

--3. 
   -- a. Which drug (generic_name) had the highest total drug cost?

   -- b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT generic_name, MAX(total_drug_cost_ge65)
FROM prescription
LEFT JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY MAX(total_drug_cost_ge65) DESC NULLS LAST;
--PIRFENIDONE


SELECT generic_name, ROUND(MAX(total_drug_cost_ge65 / 30), 2)
FROM prescription
LEFT JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY MAX(total_drug_cost_ge65) DESC NULLS LAST;
--PIRFENIDONE, 89344.43


--4.a. For each drug in the drug table, return the drug name and then a column named 'drug_type' 
	--which says 'opioid' for drugs which have opioid_drug_flag = 'Y', 
		--says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
		--and says 'neither' for all other drugs. 
	--**Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 
SELECT drug_name,
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type
FROM drug
LEFT JOIN prescription USING (drug_name);

SELECT  SUM(total_drug_cost::money),
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type
FROM drug
LEFT JOIN prescription USING (drug_name)
GROUP BY drug_type;
--opioid, $105,080,626.37

--5.
--a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(*)
FROM cbsa
WHERE cbsaname ILIKE '%TN%';
--58
  --  b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname, MAX(population)
FROM population
LEFT JOIN cbsa USING (fipscounty)
GROUP BY cbsaname
ORDER BY MAX(POPULATION) ASC;
--Largest: Memphis, TN-MS-AR, 937847
--Smallest: Morristown, TN, 63465

    --c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT *
FROM population	
LEFT JOIN cbsa USING (fipscounty)
LEFT JOIN fips_county USING (fipscounty)
	WHERE cbsa IS NULL
ORDER BY population DESC;
--SEVIER

--6. 
  --  a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT total_claim_count, drug_name
FROM prescription
WHERE total_claim_count >= 3000;

    --b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT total_claim_count, drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'Yes, this is opioid'	
	ELSE 'No, this is not opioid' END AS is_opioid
FROM prescription
	LEFT JOIN drug USING (drug_name)
WHERE total_claim_count >= 3000;
    --c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT nppes_provider_first_name, nppes_provider_last_org_name, total_claim_count, drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'Yes, this is opioid'	
	ELSE 'No, this is not opioid' END AS is_opioid
FROM prescription
	LEFT JOIN drug USING (drug_name)
	LEFT JOIN prescriber USING (npi)
WHERE total_claim_count >= 3000;

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville 
--and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations 
		--for pain management specialists (specialty_description = 'Pain Management) 
	--in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
--where the drug is an opioid (opiod_drug_flag = 'Y'). 
	--**Warning:** Double-check your query before running it. 
--You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi, drug_name
FROM prescriber	
	LEFT JOIN prescription USING (npi)
	LEFT JOIN drug USING (drug_name)
	WHERE specialty_description ILIKE '%Pain Management%' AND nppes_provider_city ILIKE '%NASHVILLE%' AND opioid_drug_flag ILIKE '%Y%';

    --b. Next, report the number of claims per drug per prescriber. 
		--Be sure to include all combinations, whether or not the prescriber had any claims. 
	--You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT npi, drug_name, COALESCE(SUM(total_claim_count), 0) AS total_claim_count
FROM prescriber	
	LEFT JOIN prescription USING (npi)
	LEFT JOIN drug USING (drug_name)
	WHERE specialty_description ILIKE '%Pain Management%' AND nppes_provider_city ILIKE '%NASHVILLE%' AND opioid_drug_flag ILIKE '%Y%'
GROUP BY drug_name, npi;
  --  c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.