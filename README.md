# Health Insurance Marketplace Analysis
🔗 Dataset: [Benefit_Cost_Sharing Public Use Files (PUF)](https://www.kaggle.com/datasets/hhs/health-insurance-marketplace)

# Objective
This project analyzes 2016 health insurance benefit cost-sharing data to quantify patient out-of-pocket expenses, including copayments, coinsurance, and deductibles.

# Why This Project?
This initiative is directly aligned with the mission of utilizing real-world patient data to enhance clinical decision-making, inform research publications, and generate meaningful insights in healthcare. It supports risk adjustment analytics, informs healthcare policy decisions, and ultimately aims to improve patient financial outcomes.

# Key Findings
**Drug Copay Structure & Incentives:** Average in-network copayments for Tier 1 ($21.41) and Tier 2 ($21.44) drugs were nearly identical, indicating minimal cost disincentives for patients utilizing preferred brand drugs over generics within these tiers in 2016.

**Coinsurance Mechanisms & Network Utilization:** A lower average Tier 2 coinsurance (7.8%) compared to Tier 1 (12.3%) might subtly incentivize preferred brands, while the substantial 28.2% average out-of-network coinsurance strongly reinforces in-network utilization, profoundly impacting the total cost of expensive therapies.

**Geographic Cost Inequities:** State-level average Tier 1 drug copayments exhibited variations (e.g., $49.60 in Montana vs. $29.44 in South Carolina), revealing significant geographic inequities in medication costs that could directly influence patient adherence and health outcomes.

**Deductible vs. Post-Deductible Costs:** Despite plans featuring individual drug deductibles exceeding $5,000, subsequent Tier 1 drug cost-sharing remained moderate ($21 copay + 12% coinsurance), indicating that the primary financial barrier for patients in these plans was often the initial deductible.

**Insurer-Specific Cost Variability:** An analysis at the issuer level unveiled stark differences in cost-sharing, with some insurers imposing exceptionally high average Tier 1 drug copayments (e.g., over $114) and coinsurance (e.g., over 15%), presenting significant financial barriers for patients accessing even basic medications.

**Adult Routine Dental Coverage: ** 3,342 analyzed health plans explicitly provided coverage for adult routine dental services in 2016, indicating specific areas of preventive care inclusion but also highlighting potential gaps in broader benefit availability.

# Methodology
Data Acquisition & Preparation: Established a dedicated SQLite database and imported the raw 2016 Health Insurance Benefit Cost Sharing dataset.
Data Wrangling & Cleaning: Executed precise SQL ALTER TABLE and UPDATE statements to:
Standardize the ImportDate column into a consistent YYYY-MM-DD date format.
Create dedicated REAL (decimal) columns for all core cost-sharing metrics (e.g., CleanedCopayInnTier1, CleanedCoinsInnTier1, CleanedDrugDeductibleIndividual).
Implement CASE statements and REPLACE functions to robustly convert raw text values (including currency symbols, percentages, and "Not Applicable") into analyzable numerical data.
Exploratory Data Analysis (EDA): Leveraged advanced SQL aggregations (AVG, COUNT), grouping (GROUP BY), and conditional logic (CASE) to uncover average cost-sharing values, distribution of benefit limits, and coverage prevalence for critical services.
