/* =====================================================================
   ALL TEST-CASE INSERT SCRIPTS — arapl_RunILSAnalysis_SR Testing Engagement
   Organized by phase, in the order they were built and run.
   Each phase is self-contained (creates its own isolated instrument/
   activity/layer) except where noted as reusing real Baldwin Re data
   (LossSetID = 900040, ActivityID = 40).
   ===================================================================== */


/* =====================================================================
   PHASE 1-2: Deductible Types + Reinstatement Premium
   Tested on REAL layer 345 (Baldwin Re) via UPDATEs, not new inserts,
   EXCEPT the Reinstatement Premium ceiling test which needed a new
   isolated layer (2805) since real data couldn't reach the fully-
   exhausted band.
   ===================================================================== */

-- Deductible tests: real layer 345, modified via UPDATE (not INSERT)
-- e.g. UPDATE ILSTerms SET DeductibleType = 1, CompanyLossMinimum = 75000000 WHERE ILSTermsID = 345
-- (see full change log for the complete sequence of UPDATEs to layer 345)

-- Reinstatement Premium test layer (2805) - isolated, reused real Baldwin Re loss data
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention,
     ReinstatementPremium, PercentAnnualSpread, PrincipalAmount,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (40, 40, 'CATXOL',
     'USD', '2025-07-01', '2029-06-30',
     1, 0, 1,
     50000000, 100000000,
     '1@50,1@100', 0.05, 50000000,
     1, 1, 'N', NULL);

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF)
VALUES (2805, 900040, 1);

-- Synthetic data for the fully-exhausted ceiling case (Change 10, Phase 2)
INSERT INTO ARAPL_Configuration_v13.dbo.LossSetMetaData (ActivityId, LossSetName, isDeleted, isModeledLoss)
VALUES (999001, 'SYNTHETIC TEST - Reinstatement Premium ceiling check', 0, 'Y');
-- generated LossSetID = 900042

DROP TABLE IF EXISTS ARAPL_Data_v13.dbo.YELT_999001;
SELECT * INTO ARAPL_Data_v13.dbo.YELT_999001
FROM (VALUES
    (CAST(1 AS BIGINT), CAST(1 AS INT), CAST(1 AS INT), CAST(500000000 AS FLOAT)),
    (CAST(2 AS BIGINT), CAST(1 AS INT), CAST(2 AS INT), CAST(500000000 AS FLOAT)),
    (CAST(3 AS BIGINT), CAST(1 AS INT), CAST(3 AS INT), CAST(500000000 AS FLOAT))
) AS t(EventID, YearID, DayID, PreCatLoss);

UPDATE ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation
SET LossSetID = 900042, LMF = 1
WHERE ILSTermsID = 2805;


/* =====================================================================
   PHASE 3: CATBOND Unlimited-Occurrence-Limit Cap (item 6)
   Isolated test layer 2806, cloning real layer 344's terms.
   ===================================================================== */

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention,
     AggregateLimit, AggregateRetention,
     PrincipalAmount, PercentAnnualSpread, Reinstatement,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (40, 40, 'CATBOND',
     'USD', '2025-07-01', '2029-06-30',
     1, 0, 1,
     NULL, 500000000,
     NULL, NULL,
     250000000, 0.0375, 0,
     1, 1, 'N', NULL);
-- generated ILSTermsID = 2806

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF)
VALUES (2806, 900040, 1);


/* =====================================================================
   PHASE 4: RPP - Swap Mechanism + @ROL Rate Fix (items 7a/7b)
   New isolated instrument (338), two linked layers: container (2807)
   and protection layer (2808).
   ===================================================================== */

INSERT INTO ARAPL_Configuration_v13.dbo.ILSData (ILSName, Security_or_Reinsurance_Type)
VALUES ('SYNTHETIC TEST - RPP structure', 'CAT Bond');
-- generated ILSInstrumentID = 338

INSERT INTO ARAPL_Configuration_v13.dbo.ILSActivityMonitor
    (JobId, UserId, ARADbName, AcctName, AcctGrpId,
     AnalysisType, ShapeId, Peril, JobStatus, CurrencyCode)
VALUES (1000, 'TestUser', '', '', 338, 0, 0, 0, 0, 'USD');
-- generated ActivityID = 338

-- Layer B (container) - InuringSequenceNumber=1, ParentRelationType=4
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention, AggregateLimit, AggregateRetention,
     PrincipalAmount, PercentAnnualSpread, Reinstatement,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (338, 338, 'CATXOL', 'USD', '2025-07-01', '2029-06-30',
     1, 0, 4,
     100000000, 0, NULL, NULL,
     NULL, NULL, 0, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2807

-- Layer A (RPP protection) - InuringSequenceNumber=2, ParentRelationType=1, feeds into B
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention, AggregateLimit, AggregateRetention,
     ReinstatementPremium, PercentAnnualSpread, PrincipalAmount,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (338, 338, 'CATXOL', 'USD', '2025-07-01', '2029-06-30',
     2, 2807, 1,
     50000000, 100000000, NULL, NULL,
     '1@50,1@100', 0.05, 50000000, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2808

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF)
VALUES (2808, 900040, 1);
-- NOTE: an unexplained stray association also appeared on 2807 pointing at 900040 -
-- root cause never identified; was deleted (see Change 18 in the full log)

-- Phase 4 @ROL fix test: populate LayerPremium on the container (2807), test-only value
UPDATE ARAPL_Configuration_v13.dbo.ILSTerms
SET LayerPremium = 2000000
WHERE ILSTermsID = 2807;


/* =====================================================================
   PHASE 5: AGGTRIGGER (item 8)
   New isolated instrument (339), single layer (2809).
   ===================================================================== */

INSERT INTO ARAPL_Configuration_v13.dbo.ILSData (ILSName, Security_or_Reinsurance_Type)
VALUES ('SYNTHETIC TEST - AGGTRIGGER structure', 'Reinsurance');
-- generated ILSInstrumentID = 339

INSERT INTO ARAPL_Configuration_v13.dbo.ILSActivityMonitor
    (JobId, UserId, ARADbName, AcctName, AcctGrpId,
     AnalysisType, ShapeId, Peril, JobStatus, CurrencyCode)
VALUES (1000, 'TestUser', '', '', 339, 0, 0, 0, 0, 'USD');
-- generated ActivityID = 339

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention,
     AggregateLimit, AggregateRetention,
     PrincipalAmount, PercentAnnualSpread,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (339, 339, 'AGGTRIGGER', 'USD', '2025-07-01', '2029-06-30',
     1, 0, 1,
     NULL, NULL,
     NULL, 500000000,
     100000000, 0.0375, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2809 (initially mis-created under wrong instrument/activity - see log)

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF)
VALUES (2809, 900040, 1);


/* =====================================================================
   PHASE 6: OCCTRIGGER (item 9)
   New isolated instrument (340), single layer (2810).
   ===================================================================== */

INSERT INTO ARAPL_Configuration_v13.dbo.ILSData (ILSName, Security_or_Reinsurance_Type)
VALUES ('SYNTHETIC TEST - OCCTRIGGER structure', 'Reinsurance');
-- generated ILSInstrumentID = 340, ActivityID = 340

INSERT INTO ARAPL_Configuration_v13.dbo.ILSActivityMonitor
    (JobId, UserId, ARADbName, AcctName, AcctGrpId,
     AnalysisType, ShapeId, Peril, JobStatus, CurrencyCode)
VALUES (1000, 'TestUser', '', '', 340, 0, 0, 0, 0, 'USD');

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention,
     PrincipalAmount, PercentAnnualSpread,
     CompanyLossMinimum, StartingEventNumber,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (340, 340, 'OCCTRIGGER', 'USD', '2025-07-01', '2029-06-30',
     1, 0, 1,
     NULL, NULL,
     75000000, 0.0375,
     10000000, 2, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2810

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF)
VALUES (2810, 900040, 1);


/* =====================================================================
   PHASE 7: PRORATA (item 10)
   New isolated instrument (341), single layer (2811).
   ===================================================================== */

INSERT INTO ARAPL_Configuration_v13.dbo.ILSData (ILSName, Security_or_Reinsurance_Type)
VALUES ('SYNTHETIC TEST - PRORATA structure', 'Reinsurance');
-- generated ILSInstrumentID = 341, ActivityID = 341

INSERT INTO ARAPL_Configuration_v13.dbo.ILSActivityMonitor
    (JobId, UserId, ARADbName, AcctName, AcctGrpId,
     AnalysisType, ShapeId, Peril, JobStatus, CurrencyCode)
VALUES (1000, 'TestUser', '', '', 341, 0, 0, 0, 0, 'USD');

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     AggregateLimit, AggregateRetention,
     PrincipalAmount, PercentAnnualSpread, StartingEventNumber,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (341, 341, 'PRORATA', 'USD', '2025-07-01', '2029-06-30',
     1, 0, 1,
     100000000, 0,
     50000000, 0.0375, 2, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2811

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF)
VALUES (2811, 900040, 1);


/* =====================================================================
   PHASE 8: OCCILW (item 11)
   New isolated instrument (342), single layer (2812).
   ===================================================================== */

INSERT INTO ARAPL_Configuration_v13.dbo.ILSData (ILSName, Security_or_Reinsurance_Type)
VALUES ('SYNTHETIC TEST - OCCILW structure', 'Reinsurance');
-- generated ILSInstrumentID = 342, ActivityID = 342

INSERT INTO ARAPL_Configuration_v13.dbo.ILSActivityMonitor
    (JobId, UserId, ARADbName, AcctName, AcctGrpId,
     AnalysisType, ShapeId, Peril, JobStatus, CurrencyCode)
VALUES (1000, 'TestUser', '', '', 342, 0, 0, 0, 0, 'USD');

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention,
     AggregateLimit, AggregateRetention,
     PrincipalAmount, PercentAnnualSpread,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (342, 342, 'OCCILW', 'USD', '2025-07-01', '2029-06-30',
     1, 0, 1,
     50000000, 100000000,
     50000000, 0,
     25000000, 0.0375, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2812

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF)
VALUES (2812, 900040, 1);


/* =====================================================================
   PHASE 9: GU / ELSE Catch-All + CATBOND parent (item 14)
   New isolated instrument (343): CATBOND parent (2813) + GU child (2814).
   ===================================================================== */

INSERT INTO ARAPL_Configuration_v13.dbo.ILSData (ILSName, Security_or_Reinsurance_Type)
VALUES ('SYNTHETIC TEST - GU pass-through structure', 'CAT Bond');
-- generated ILSInstrumentID = 343, ActivityID = 343

INSERT INTO ARAPL_Configuration_v13.dbo.ILSActivityMonitor
    (JobId, UserId, ARADbName, AcctName, AcctGrpId,
     AnalysisType, ShapeId, Peril, JobStatus, CurrencyCode)
VALUES (1000, 'TestUser', '', '', 343, 0, 0, 0, 0, 'USD');

-- CATBOND parent
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention,
     PrincipalAmount, PercentAnnualSpread,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (343, 343, 'CATBOND', 'USD', '2025-07-01', '2029-06-30',
     1, 0, 1,
     999000000, 0, 100000000, 0.0375, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2813

-- GU child - ParentRelationType=3, matching the real pattern found in production
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (343, 343, 'GU', 'USD', '2025-07-01', '2029-06-30',
     2, 2813, 3, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2814

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF)
VALUES (2814, 900040, 1);


/* =====================================================================
   PHASE 10: Drop-Down Cover (item 15)
   Required a test-only schema addition (StepLayerSequenceNumber) before
   any layers could be built. New isolated instrument (344): primary (2815)
   + step-layer (2816). Also required synthetic loss data matching AIR's
   own 4-event documented example exactly.
   ===================================================================== */

-- Test-only schema addition (real production ILSTerms has NO such column -
-- confirmed via the real ARAPL_populate_ILSTerms source, Phase 15)
ALTER TABLE ARAPL_Configuration_v13.dbo.ILSTerms
ADD StepLayerSequenceNumber INT NULL;

INSERT INTO ARAPL_Configuration_v13.dbo.ILSData (ILSName, Security_or_Reinsurance_Type)
VALUES ('SYNTHETIC TEST - Drop-Down Cover structure', 'Reinsurance');
-- generated ILSInstrumentID = 344, ActivityID = 344

INSERT INTO ARAPL_Configuration_v13.dbo.ILSActivityMonitor
    (JobId, UserId, ARADbName, AcctName, AcctGrpId,
     AnalysisType, ShapeId, Peril, JobStatus, CurrencyCode)
VALUES (1000, 'TestUser', '', '', 344, 0, 0, 0, 0, 'USD');

-- Primary layer, matching AIR's documented example exactly ($30M limit / $60M retention)
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType, StepLayerSequenceNumber,
     OccurrenceLimit, OccurrenceRetention,
     PrincipalAmount, PercentAnnualSpread,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (344, 344, 'CATXOL', 'USD', '2025-07-01', '2029-06-30',
     1, 0, 1, 1,
     30000000, 60000000, 30000000, 0.0375, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2815

-- Step-layer, matching AIR's example exactly ($30M limit / $30M retention)
-- ParentRelationType = 5, a value invented this engagement (never produced by
-- the real TSRe conversion, confirmed Phase 15)
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType, StepLayerSequenceNumber,
     OccurrenceLimit, OccurrenceRetention,
     ReinstatementPremium, PercentAnnualSpread, PrincipalAmount,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (344, 344, 'CATXOL', 'USD', '2025-07-01', '2029-06-30',
     2, 2815, 5, 2,
     30000000, 30000000, NULL, 0.0375, 30000000, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2816

-- Synthetic loss data - exact 4-event sequence from AIR's own worked example
DROP TABLE IF EXISTS ARAPL_Data_v13.dbo.YELT_999002;
SELECT * INTO ARAPL_Data_v13.dbo.YELT_999002
FROM (VALUES
    (CAST(999000001 AS BIGINT), CAST(1 AS INT), CAST(1 AS INT), CAST(40000000 AS FLOAT)),
    (CAST(999000002 AS BIGINT), CAST(1 AS INT), CAST(2 AS INT), CAST(90000000 AS FLOAT)),
    (CAST(999000003 AS BIGINT), CAST(1 AS INT), CAST(3 AS INT), CAST(20000000 AS FLOAT)),
    (CAST(999000004 AS BIGINT), CAST(1 AS INT), CAST(4 AS INT), CAST(50000000 AS FLOAT))
) AS t(EventID, YearID, DayID, PreCatLoss);

INSERT INTO ARAPL_Configuration_v13.dbo.LossSetMetaData (ActivityId, LossSetName, isDeleted, isModeledLoss)
VALUES (999002, 'SYNTHETIC TEST - Drop-Down Cover PDF example', 0, 'Y');
-- generated LossSetID = 900044 (after cleaning up an earlier accidental duplicate insert)

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF)
VALUES (2815, 900044, 1);
-- NOTE: only the PRIMARY layer gets the association; the step-layer's terms
-- are read by reference from within the primary's own processing, never
-- standalone.


/* =====================================================================
   PHASE 11: Multi-Child Sourcing/Inuring at One Parent (structural test)
   New isolated instrument (345): CATBOND parent (2817) + 3 CATXOL
   children - 2 sourced (2819, 2822), 1 inuring (2820).
   ===================================================================== */

INSERT INTO ARAPL_Configuration_v13.dbo.ILSData (ILSName, Security_or_Reinsurance_Type)
VALUES ('SYNTHETIC TEST - Multi-child sourcing/inuring', 'CAT Bond');
-- generated ILSInstrumentID = 345, ActivityID = 345

INSERT INTO ARAPL_Configuration_v13.dbo.ILSActivityMonitor
    (JobId, UserId, ARADbName, AcctName, AcctGrpId,
     AnalysisType, ShapeId, Peril, JobStatus, CurrencyCode)
VALUES (1000, 'TestUser', '', '', 345, 0, 0, 0, 0, 'USD');

-- CATBOND parent
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention,
     PrincipalAmount, PercentAnnualSpread,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (345, 345, 'CATBOND', 'USD', '2025-07-01', '2029-06-30',
     1, 0, 1, 999000000, 0, 100000000, 0.0375, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2817

-- Child A: sourced, one event Loss=$8M
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode, CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention, PrincipalAmount, PercentAnnualSpread,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (345, 345, 'CATXOL', 'USD', '2025-07-01', '2029-06-30',
     2, 2817, 1, 10000000, 0, 10000000, 0.0375, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2819

-- Child C: inuring, one event Loss=$9M
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode, CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention, PrincipalAmount, PercentAnnualSpread,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (345, 345, 'CATXOL', 'USD', '2025-07-01', '2029-06-30',
     2, 2817, 2, 5000000, 2000000, 5000000, 0.0375, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2820

-- Child B: sourced, one event Loss=$6M (re-created after an earlier attempt
-- corrupted with placeholder values not substituted - see log Change entries)
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode, CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention, PrincipalAmount, PercentAnnualSpread,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (345, 345, 'CATXOL', 'USD', '2025-07-01', '2029-06-30',
     2, 2817, 1, 10000000, 0, 10000000, 0.0375, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2822

-- Synthetic loss data - 3 separate loss sets, one event each
DROP TABLE IF EXISTS ARAPL_Data_v13.dbo.YELT_999003;
SELECT * INTO ARAPL_Data_v13.dbo.YELT_999003
FROM (VALUES (CAST(999100001 AS BIGINT), CAST(1 AS INT), CAST(1 AS INT), CAST(8000000 AS FLOAT))) AS t(EventID, YearID, DayID, PreCatLoss);

DROP TABLE IF EXISTS ARAPL_Data_v13.dbo.YELT_999004;
SELECT * INTO ARAPL_Data_v13.dbo.YELT_999004
FROM (VALUES (CAST(999100002 AS BIGINT), CAST(1 AS INT), CAST(1 AS INT), CAST(6000000 AS FLOAT))) AS t(EventID, YearID, DayID, PreCatLoss);

DROP TABLE IF EXISTS ARAPL_Data_v13.dbo.YELT_999005;
SELECT * INTO ARAPL_Data_v13.dbo.YELT_999005
FROM (VALUES (CAST(999100003 AS BIGINT), CAST(1 AS INT), CAST(1 AS INT), CAST(9000000 AS FLOAT))) AS t(EventID, YearID, DayID, PreCatLoss);

INSERT INTO ARAPL_Configuration_v13.dbo.LossSetMetaData (ActivityId, LossSetName, isDeleted, isModeledLoss) VALUES (999003, 'SYNTHETIC TEST - Child A', 0, 'Y');
INSERT INTO ARAPL_Configuration_v13.dbo.LossSetMetaData (ActivityId, LossSetName, isDeleted, isModeledLoss) VALUES (999004, 'SYNTHETIC TEST - Child B', 0, 'Y');
INSERT INTO ARAPL_Configuration_v13.dbo.LossSetMetaData (ActivityId, LossSetName, isDeleted, isModeledLoss) VALUES (999005, 'SYNTHETIC TEST - Child C', 0, 'Y');
-- generated LossSetIDs = 900045 (A), 900046 (B), 900047 (C)

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF) VALUES (2819, 900045, 1);
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF) VALUES (2822, 900046, 1);
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF) VALUES (2820, 900047, 1);


/* =====================================================================
   PHASE 12-13: Coinsurance (item 13)
   New isolated instrument (346), single layer (2823).
   ===================================================================== */

INSERT INTO ARAPL_Configuration_v13.dbo.ILSData (ILSName, Security_or_Reinsurance_Type)
VALUES ('SYNTHETIC TEST - Coinsurance', 'Reinsurance');
-- generated ILSInstrumentID = 346, ActivityID = 346

INSERT INTO ARAPL_Configuration_v13.dbo.ILSActivityMonitor
    (JobId, UserId, ARADbName, AcctName, AcctGrpId,
     AnalysisType, ShapeId, Peril, JobStatus, CurrencyCode)
VALUES (1000, 'TestUser', '', '', 346, 0, 0, 0, 0, 'USD');

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode,
     CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention,
     PrincipalAmount, PercentAnnualSpread, CoinsuranceAmount,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (346, 346, 'CATXOL', 'USD', '2025-07-01', '2029-06-30',
     1, 0, 1,
     999000000, 0, 100000, 0.0375, 0.30, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2823

DROP TABLE IF EXISTS ARAPL_Data_v13.dbo.YELT_999006;
SELECT * INTO ARAPL_Data_v13.dbo.YELT_999006
FROM (VALUES (CAST(999200001 AS BIGINT), CAST(1 AS INT), CAST(1 AS INT), CAST(100000 AS FLOAT))) AS t(EventID, YearID, DayID, PreCatLoss);

INSERT INTO ARAPL_Configuration_v13.dbo.LossSetMetaData (ActivityId, LossSetName, isDeleted, isModeledLoss)
VALUES (999006, 'SYNTHETIC TEST - Coinsurance', 0, 'Y');
-- generated LossSetID = <check for exact ID generated>

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF)
VALUES (2823, 900048, 1);  -- substitute the real generated LossSetID if different


/* =====================================================================
   PHASE 14: Quota Share Ceded % - v1 design (SUPERSEDED by Phase 15)
   New isolated instrument (347), single layer (2824).
   Kept here for completeness/history - ILSTermsCessionRules and
   ILSTermsCessionCombined are NO LONGER USED by the deployed procedure.
   ===================================================================== */

INSERT INTO ARAPL_Configuration_v13.dbo.ILSData (ILSName, Security_or_Reinsurance_Type)
VALUES ('SYNTHETIC TEST - Cession Rules', 'Reinsurance');
-- generated ILSInstrumentID = 347, ActivityID = 347

INSERT INTO ARAPL_Configuration_v13.dbo.ILSActivityMonitor
    (JobId, UserId, ARADbName, AcctName, AcctGrpId,
     AnalysisType, ShapeId, Peril, JobStatus, CurrencyCode)
VALUES (1000, 'TestUser', '', '', 347, 0, 0, 0, 0, 'USD');

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode, CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention, PrincipalAmount, PercentAnnualSpread,
     QS_Cession, CoinsuranceAmount,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (347, 347, 'QS', 'USD', '2025-07-01', '2029-06-30',
     1, 0, 1,
     999000000, 0, 1000000, 0.0375,
     0.20, 0, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2824

-- (SUPERSEDED) v1 cession rules table and rows - see Phase 15 for the final design
-- CREATE TABLE ARAPL_Configuration_v13.dbo.ILSTermsCessionRules (...)
-- INSERT INTO ILSTermsCessionRules (ILSTermsID, PerilID, CountryID, StateCode, CededPercent)
-- VALUES (2824, 2, NULL, NULL, 0.40), (2824, NULL, 168, NULL, 0.30),
--        (2824, NULL, 168, 'FL', 0.50), (2824, 2, 168, 'FL', 0.60)


/* =====================================================================
   PHASE 15: Quota Share Ceded % - FINAL design (this is the one actually
   deployed and confirmed working)
   New isolated instrument (348), single layer (2825).
   Uses REAL AIR geography data (GeographySID) - US=234, Georgia=251.
   ===================================================================== */

-- Schema changes (real, permanent additions to ILSTermsRegion/ILSTermsPeril)
ALTER TABLE ARAPL_Configuration_v13.dbo.ILSTermsRegion
ADD GeographySID INT NULL, CededPercent FLOAT NULL;

ALTER TABLE ARAPL_Configuration_v13.dbo.ILSTermsPeril
ADD GeographySID INT NULL, CededPercent FLOAT NULL;
-- (ILSTermsCessionCombined table was created then dropped during design iteration - not used)

INSERT INTO ARAPL_Configuration_v13.dbo.ILSData (ILSName, Security_or_Reinsurance_Type)
VALUES ('SYNTHETIC TEST - Geography Cession v2', 'Reinsurance');
-- generated ILSInstrumentID = 348, ActivityID = 348

INSERT INTO ARAPL_Configuration_v13.dbo.ILSActivityMonitor
    (JobId, UserId, ARADbName, AcctName, AcctGrpId,
     AnalysisType, ShapeId, Peril, JobStatus, CurrencyCode)
VALUES (1000, 'TestUser', '', '', 348, 0, 0, 0, 0, 'USD');

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTerms
    (ILSInstrumentID, AnalysisSID, ReinsuranceTypeCode, CurrencyCode, InceptionDate, ExpirationDate,
     InuringSequenceNumber, ParentILSTermsID, ParentRelationType,
     OccurrenceLimit, OccurrenceRetention, PrincipalAmount, PercentAnnualSpread,
     QS_Cession, CoinsuranceAmount,
     ParticipationGross, ParticipationNet, IsDeleted, DeductibleType)
VALUES
    (348, 348, 'QS', 'USD', '2025-07-01', '2029-06-30',
     1, 0, 1,
     999000000, 0, 1000000, 0.0375,
     0.20, 0, 1, 1, 'N', NULL);
-- generated ILSTermsID = 2825

-- Cession rules (final design: ILSTermsRegion for geography-only, ILSTermsPeril for
-- peril-only AND peril+geography combined, via optional GeographySID)
INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsRegion (ILSTermsID, CountryID, GeographySID, CededPercent)
VALUES (2825, 168, 251, 0.50);   -- Georgia state rule

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsRegion (ILSTermsID, CountryID, GeographySID, CededPercent)
VALUES (2825, 168, 234, 0.30);   -- US country rule

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsPeril (ILSTermsID, PerilID, GeographySID, CededPercent)
VALUES (2825, 2, NULL, 0.40);    -- Wind, everywhere

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsPeril (ILSTermsID, PerilID, GeographySID, CededPercent)
VALUES (2825, 2, 251, 0.70);     -- Wind, specifically in Georgia (most specific)

-- Synthetic loss + Stoch substitute data (5 events covering all 4 priority
-- levels + genuine non-US fallback)
DROP TABLE IF EXISTS ARAPL_Data_v13.dbo.YELT_999008;
SELECT * INTO ARAPL_Data_v13.dbo.YELT_999008
FROM (VALUES
    (CAST(999400001 AS BIGINT), CAST(1 AS INT), CAST(1 AS INT), CAST(100000 AS FLOAT)),
    (CAST(999400002 AS BIGINT), CAST(1 AS INT), CAST(2 AS INT), CAST(110000 AS FLOAT)),
    (CAST(999400003 AS BIGINT), CAST(1 AS INT), CAST(3 AS INT), CAST(120000 AS FLOAT)),
    (CAST(999400004 AS BIGINT), CAST(1 AS INT), CAST(4 AS INT), CAST(130000 AS FLOAT)),
    (CAST(999400005 AS BIGINT), CAST(1 AS INT), CAST(5 AS INT), CAST(140000 AS FLOAT))
) AS t(EventID, YearID, DayID, PreCatLoss);

-- TEST-ONLY substitute for SummaryIndustryLoss_Stoch_Final (real table protected -
-- procedure's join was temporarily repointed here for testing, then reverted)
CREATE TABLE ARAPL_Configuration_v13.dbo.TEST_SummaryIndustryLoss_Stoch_Final_v2 (
    EventID BIGINT, CountryID INT, CountryCode VARCHAR(10), StateCode VARCHAR(10), PerilID INT
);

INSERT INTO ARAPL_Configuration_v13.dbo.TEST_SummaryIndustryLoss_Stoch_Final_v2
    (EventID, CountryID, CountryCode, StateCode, PerilID)
VALUES
    (999400001, 168, 'US', 'TX', 1),   -- Event A: EQ, Texas -> country rule
    (999400002, 168, 'US', 'TX', 2),   -- Event B: Wind, Texas -> plain peril rule
    (999400003, 168, 'US', 'GA', 1),   -- Event C: EQ, Georgia -> state rule
    (999400004, 168, 'US', 'GA', 2),   -- Event D: Wind, Georgia -> combined rule (most specific)
    (999400005, 49, 'JP', NULL, 7);    -- Event E: Flood, Japan -> genuine fallback to treaty default

INSERT INTO ARAPL_Configuration_v13.dbo.LossSetMetaData (ActivityId, LossSetName, isDeleted, isModeledLoss)
VALUES (999008, 'SYNTHETIC TEST - Geography Cession v2', 0, 'Y');
-- generated LossSetID = <check for exact ID generated>

INSERT INTO ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation (ILSTermsID, LossSetID, LMF)
VALUES (2825, <@NewLossSetID>, 1);  -- substitute the real generated LossSetID

/* Expected results, confirmed exact:
   A (EQ/TX)    = 100,000 x 0.30 = 30,000
   B (Wind/TX)  = 110,000 x 0.40 = 44,000
   C (EQ/GA)    = 120,000 x 0.50 = 60,000
   D (Wind/GA)  = 130,000 x 0.70 = 91,000
   E (Flood/JP) = 140,000 x 0.20 = 28,000
*/


/* =====================================================================
   CLEANUP - all test artifacts, if/when you want to remove them
   (NOT run as part of this engagement - listed for reference only)
   ===================================================================== */
-- DELETE FROM ARAPL_Configuration_v13.dbo.ILSTermsLossSetAssociation WHERE ILSTermsID IN (2805,2806,2807,2808,2809,2810,2811,2812,2813,2814,2815,2816,2817,2819,2820,2822,2823,2824,2825);
-- DELETE FROM ARAPL_Configuration_v13.dbo.ILSTerms WHERE ILSTermsID IN (2805,2806,2807,2808,2809,2810,2811,2812,2813,2814,2815,2816,2817,2819,2820,2822,2823,2824,2825);
-- DELETE FROM ARAPL_Configuration_v13.dbo.ILSActivityMonitor WHERE ActivityID BETWEEN 338 AND 348;
-- DELETE FROM ARAPL_Configuration_v13.dbo.ILSData WHERE ILSInstrumentID BETWEEN 338 AND 348;
-- DROP TABLE IF EXISTS ARAPL_Configuration_v13.dbo.TEST_SummaryIndustryLoss_Stoch_Final_v2;
-- DROP TABLE IF EXISTS ARAPL_Configuration_v13.dbo.ILSTermsCessionRules;   -- Phase 14, superseded
-- DROP TABLE IF EXISTS ARAPL_Data_v13.dbo.YELT_999001;  -- (and 999002-999008)
