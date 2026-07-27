/*******************************************************************************************
Purpose:
    Deletes test portfolio data (portfolios with 'TEST' in the name) and, optionally,
    their associated PnL/report results, from both parent and child tables.

Inputs:
    @Commit INT = 0
        0 -> Preview only. Shows record counts that WOULD be deleted. No data is changed.
        1 -> Delete RESULTS only (dynamic per-export result tables + ILSActivityMonitor rows).
        2 -> Delete PORTFOLIO data only (PortfolioReport and related child tables).
        3 -> Delete BOTH results and portfolio data.

Notes:
    - Portfolios are identified by Name LIKE '%TEST%'. Confirm this still matches your
      test-data naming convention before running with @Commit <> 0.
    - If @Commit = 2 is used without also using 1 or 3, any ILSActivityMonitor rows
      linked to the deleted portfolios (via AccPortSrNo) will be left orphaned.
******************************************************************************************/

CREATE PROCEDURE dbo.usp_DeleteTestPortfolio
(
      @Commit INT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRAN;

        DECLARE @Portfolio TABLE
        (
            id INT IDENTITY(1,1),
            PortfolioID INT,
            PortfolioName NVARCHAR(255)
        );

        DECLARE @PortfolioResults TABLE
        (
            id INT IDENTITY(1,1),
            PortfolioID INT,
            PortfolioName NVARCHAR(255),
            Activityid INT,
            Exportid INT
        );

        INSERT INTO @Portfolio (PortfolioID, PortfolioName)
        SELECT PortfolioID, [Name]
        FROM PortfolioReport
        WHERE Name LIKE '%TEST%';

        IF NOT EXISTS (SELECT 1 FROM @Portfolio)
        BEGIN
            PRINT 'No matching portfolios found.';
            COMMIT TRAN;
            RETURN;
        END

        INSERT INTO @PortfolioResults (PortfolioID, PortfolioName, Activityid, Exportid)
        SELECT p.PortfolioID, p.PortfolioName, a.ActivityID, a.[Description] AS Exportid
        FROM @Portfolio p
        INNER JOIN ILSActivityMonitor a ON a.AccPortSrNo = p.PortfolioID
        WHERE a.ActivityAnalysisType = ''; /* reinsurance portfolio only */

        -------------------------------------------------------
        -- Preview: counts of records that WOULD be deleted
        -------------------------------------------------------
        PRINT 'DELETE PORTFOLIO DETAILS (PREVIEW)';
        SELECT 'PortfolioReport' AS TableName, COUNT(*) AS RecordsToDelete
        FROM PortfolioReport
        WHERE PortfolioID IN (SELECT PortfolioID FROM @Portfolio)
        UNION ALL
        SELECT 'PortfolioSettings', COUNT(*) FROM PortfolioSettings
        WHERE PortfolioID IN (SELECT PortfolioID FROM @Portfolio)
        UNION ALL
        SELECT 'PortfolioReportDetails', COUNT(*)
        FROM PortfolioReportDetails
        WHERE PortfolioID IN (SELECT PortfolioID FROM @Portfolio)
        UNION ALL
        SELECT 'TransactionTable', COUNT(*)
        FROM TransactionTable
        WHERE PortfolioID IN (SELECT PortfolioID FROM @Portfolio)
        UNION ALL
        SELECT 'TransactionILSMapping', COUNT(*)
        FROM TransactionILSMapping M
        INNER JOIN TransactionTable T ON M.TransactionID = T.TransactionID
        WHERE T.PortfolioID IN (SELECT PortfolioID FROM @Portfolio)
        UNION ALL
        SELECT 'Guidelines', COUNT(*) FROM Guidelines
        WHERE PortfolioID IN (SELECT PortfolioID FROM @Portfolio)
        UNION ALL
        SELECT 'ILSActivityMonitor (results)', COUNT(*)
        FROM @PortfolioResults;

        -------------------------------------------------------
        -- Delete RESULTS (per-export tables + activity monitor rows)
        -------------------------------------------------------
        IF @Commit IN (1, 3)
        BEGIN
            DECLARE @Cnt INT = 1;
            DECLARE @MaxCnt INT;
            DECLARE @ExportID INT;
            DECLARE @SQL NVARCHAR(MAX);

            SELECT @MaxCnt = COUNT(*) FROM @PortfolioResults;

            WHILE @Cnt <= @MaxCnt
            BEGIN
                SELECT @ExportID = ExportID FROM @PortfolioResults WHERE id = @Cnt;

                -- Drop all tables for this ExportID
                SET @SQL = '
                    DROP TABLE IF EXISTS ARAPL_Works.dbo.BoundPortfolio_RegionPeril_UI_' + CAST(@ExportID AS VARCHAR(20)) + ';
                    DELETE FROM ARAPL_Works.dbo.arapl_getBoundPortfolio_PnLReport_UI WHERE ExportID = ' + CAST(@ExportID AS VARCHAR(20)) + ';
                    DELETE FROM ARAPL_Works.dbo.UI_PnL_Results WHERE ExportID = ' + CAST(@ExportID AS VARCHAR(20)) + ';
                    DELETE FROM ARAPL_Works.dbo.UI_PortfolioMetics WHERE ExportID = ' + CAST(@ExportID AS VARCHAR(20)) + ';
                    DELETE FROM ARAPL_Works.dbo.arapl_getBoundPortfolio_PortfolioMetrics_UI WHERE ExportID = ' + CAST(@ExportID AS VARCHAR(20)) + ';
                    DELETE FROM ARAPL_Works.dbo.UI_BoundPortfolio_LimitBySecurityInstrument WHERE ExportID = ' + CAST(@ExportID AS VARCHAR(20)) + ';
                    DELETE FROM ARAPL_Works.dbo.arapl_getBoundPortfolio_LimitbyIssuer_UI WHERE ExportID = ' + CAST(@ExportID AS VARCHAR(20)) + ';
                    DELETE FROM ARAPL_Works.dbo.[UI_EPCurve] WHERE ExportID = ' + CAST(@ExportID AS VARCHAR(20)) + ';
                    DELETE FROM ARAPL_Works.dbo.UI_ILS_Monthly_PremiumBreakup WHERE ExportID = ' + CAST(@ExportID AS VARCHAR(20)) + ';
                    DELETE FROM ILSActivityMonitor WHERE Description = ' + CONVERT(VARCHAR(20), @ExportID) + ';
                ';

                PRINT @SQL;
                EXEC sp_executesql @SQL;

                SET @Cnt = @Cnt + 1;
            END;
        END;

        -------------------------------------------------------
        -- Delete PORTFOLIO data (parent + child tables)
        -------------------------------------------------------
        IF @Commit IN (2, 3)
        BEGIN
            DELETE M
            FROM TransactionILSMapping M
            INNER JOIN TransactionTable T ON M.TransactionID = T.TransactionID
            WHERE T.PortfolioID IN (SELECT PortfolioID FROM @Portfolio);

            DELETE FROM TransactionTable
            WHERE PortfolioID IN (SELECT PortfolioID FROM @Portfolio);

            DELETE FROM PortfolioReportDetails
            WHERE PortfolioID IN (SELECT PortfolioID FROM @Portfolio);

            DELETE FROM PortfolioSettings
            WHERE PortfolioID IN (SELECT PortfolioID FROM @Portfolio);

            DELETE FROM Guidelines
            WHERE PortfolioID IN (SELECT PortfolioID FROM @Portfolio);

            DELETE FROM PortfolioReport
            WHERE PortfolioID IN (SELECT PortfolioID FROM @Portfolio);
        END;

        COMMIT TRAN;

        PRINT 'DELETE COMPLETED SUCCESSFULLY FOR PORTFOLIO DATA TABLES';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        PRINT 'ERROR: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

-- Preview only (no changes made):
--EXEC dbo.usp_DeleteTestPortfolio @Commit = 0;

-- Delete results only:
--EXEC dbo.usp_DeleteTestPortfolio @Commit = 1;

-- Delete portfolio data only:
--EXEC dbo.usp_DeleteTestPortfolio @Commit = 2;

-- Delete both results and portfolio data:
--EXEC dbo.usp_DeleteTestPortfolio @Commit = 3;