/****** Object:  StoredProcedure [dbo].[ExecutiveRevenueBreakdown]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ExecutiveRevenueBreakdown] 
@RevenueStartMonth Date
,@SalesExecName VARCHAR(256)
AS
BEGIN
SET NOCOUNT ON;
--
SELECT r1.MappingStream	
	,v1.Month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
	,SUM(v1.NetValueStnProfit) AS NetValueStnProfit
	,DATEDIFF(m,@RevenueStartMonth,v1.MONTH) + 1 AS MonthNo
	,(SELECT MIN(r2.OrderNo) FROM ReferenceStreamMapping r2 WHERE
	r2.MappingStream = r1.MappingStream 
	AND r2.MappedStreamName = r1.MappedStreamName
	AND r2.MappingType = 'Revenue') AS OrderNo
FROM ReferenceStreamMapping r1
LEFT OUTER JOIN v_SourceExecutiveCCPTL v1
				ON v1.RevSourceName = r1.RevSourceName
				AND v1.RevStreamGroupName = r1.RevStreamGroupName
				--  Blank text allows selection of all
				AND (v1.RevStreamName = r1.RevStreamName OR r1.RevStreamName = '')
				AND v1.SalesExecName = @SalesExecName
WHERE r1.MappingType = 'Revenue'
GROUP BY r1.MappingStream 
	,v1.month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
END
GO
/****** Object:  StoredProcedure [dbo].[ForecastTrackerBreakdown]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ForecastTrackerBreakdown] 
@WeekCommencing DATE
-------------------------------------------------
AS
BEGIN
SET NOCOUNT ON
DECLARE	@Month0 DATE
		,@Month1 DATE
		,@Month2 DATE
		,@TueDate DATE
		,@WedDate DATE
		,@ThuDate DATE
		,@FriDate DATE
		,@MonDate DATE
		,@SalesGroupBreakdownPosition INT
		,@SalesGroupBreakdownName VARCHAR(30)
		,@AdventureFlag CHAR(1)
----------------------------------------------------
SET @Month0 = DATEADD(M, DATEDIFF(m,'1900/01/01', @weekCommencing),0)
SET @Month1 = DATEADD(M,1,@Month0)
SET @Month2 = DATEADD(M,2,@Month0)
SET @TueDate = DATEADD(D,1,@weekCommencing)
SET @WedDate = DATEADD(D,2,@weekCommencing)
SET @ThuDate = DATEADD(D,3,@weekCommencing)
SET @FriDate = DATEADD(D,4,@weekCommencing)
SET @MonDate = DATEADD(D,7,@weekCommencing)
--
IF OBJECT_ID('tempdb..#TempForecastTracker','U') IS NOT NULL
				DROP TABLE #TempForecastTracker
--
CREATE TABLE #TempForecastTracker (
SalesGroupBreakdownPosition INT
,SalesGroupBreakdownName VARCHAR(30)
,AdventureFlag CHAR(1)
,BookedDate DATE
,Month DATETIME
,NetValueStnProfit FLOAT)
-- Create Array of dates for Tuesday to Friday, Month - (Month+2)
DECLARE ForecastTracker_Cursor CURSOR FOR   
SELECT SalesGroupBreakdownPosition, SalesGroupBreakdownName, AdventureFlag FROM ReferenceSalesGroupBreakdownSFT
--
OPEN ForecastTracker_Cursor  
FETCH NEXT FROM ForecastTracker_Cursor   
INTO @SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag
WHILE @@FETCH_STATUS = 0  
	BEGIN
		-- Update array
		-- Tuesday
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@TueDate,@Month0,0)
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@TueDate,@Month1,0)
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@TueDate,@Month2,0)
		-- Wednesday
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@WedDate,@Month0,0)
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@WedDate,@Month1,0)
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@WedDate,@Month2,0)
		-- Thursday
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@ThuDate,@Month0,0)
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@ThuDate,@Month1,0)
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@ThuDate,@Month2,0)
		-- Friday
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@FriDate,@Month0,0)
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@FriDate,@Month1,0)
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@FriDate,@Month2,0)
		-- Monday
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@MonDate,@Month0,0)
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@MonDate,@Month1,0)
		INSERT INTO #TempForecastTracker VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag,@MonDate,@Month2,0)
		--
		FETCH NEXT FROM ForecastTracker_Cursor INTO @SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @AdventureFlag
	END
-- Close curosr
CLOSE ForecastTracker_Cursor
DEALLOCATE ForecastTracker_Cursor
----------------------------------------------------------------------
SELECT	t.SalesGroupBreakdownPosition
		,t.SalesGroupBreakdownName
		,t.AdventureFlag
		,t.BookedDate
		,t.Month
		,t.NetValueStnProfit
		+ COALESCE((	SELECT SUM(v1.NetValueStnProfit)
						FROM v_SourceForecastTracker v1
						WHERE	v1.SalesGroupBreakdownName = t.SalesGroupBreakdownName
								AND v1.BookedDate = t.BookedDate
								AND v1.Month = t.Month),0) AS NetValueStnProfit
		,COALESCE((	SELECT TOP 1 f1.Forecast 
					FROM ForecastTrackerWeeklyForecast f1
					WHERE	f1.SalesGroupBreakdownName = t.SalesGroupBreakdownName
							AND f1.WeekCommencing = @WeekCommencing
							AND f1.Month = t.Month),0) AS Forecast
FROM #TempForecastTracker t
-- Exclude House
WHERE t.SalesGroupBreakdownName <> 'House'
-- Clean up
DROP TABLE #TempForecastTracker
-----------------------------------------------------------------------------
END
GO
/****** Object:  StoredProcedure [dbo].[ForecastTrackerRefresh]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ForecastTrackerRefresh] 
AS
BEGIN
SET NOCOUNT ON;
DECLARE @StartDate DateTime, @EndDate DateTime
-- Set start date to last week if Sunday/Monday, else this week
-- Set end date to last week Sunday if Sunday/Monday, else this week
SET @StartDate = DATEADD(wk, DATEDIFF(wk, '1900/01/01', getdate() - (CASE WHEN DATEPART(DW,GETDATE()) = 1 THEN 1 ELSE 0 END)), 0)
SET @StartDate = (CASE	WHEN DATEPART(DW,getdate()) IN (1,2) THEN DATEADD(D,-7,@StartDate)
						ELSE DATEADD(D,0,@StartDate)
				  END)
SET @EndDate = DATEADD(S,-1,DATEADD(D,7,@StartDate))

-- Clear down
DELETE FROM Greens.dbo.ForecastTrackerRevenue
-- Build Refreshed Revenue
INSERT INTO ForecastTrackerRevenue SELECT * FROM
(
SELECT ORDERID, ORDERTITLE, DATASOURCECAMPAIGN, STATIONGROUPNAME, STATIONNAME AS Station, BookedMonth AS Month, [CAMPAIGN TYPE]
        ,ACTIVITYDESCRIPTION AS 'Cost Type',SPOTTYPEDESCRIPTION as SpotType, CREATEDDATETIME, SALESEXECNAME, SALESGROUPNAME, CLIENTNAME, AGENCYNAME, AgencyAndClient, Spots, [Gross Value], [Net Value Billable] as [Net Value Stn Profit]
        ,[Agency Commission] , [Net Value Billable], Vat, Total, JCN,ORDERVERSIONNO
		,(CASE	WHEN DATEPART(DW,CREATEDDATETIME) = 6 THEN DATEADD(D,3,CONVERT(DATE,CREATEDDATETIME))
				WHEN DATEPART(DW,CREATEDDATETIME) = 7 THEN DATEADD(D,2,CONVERT(DATE,CREATEDDATETIME))
				ELSE DATEADD(D,1,CONVERT(DATE,CREATEDDATETIME))
		 END) AS BookedDate
FROM CCTRAFFICLIVE.dbo.VAirtimeRevenueByExecByOrderInclFree WITH (nolock)
        WHERE CREATEDDATETIME BETWEEN @StartDate AND @EndDate
		AND SPOTTYPEDESCRIPTION <> 'CONTRA'
UNION
SELECT ORDERID, ORDERTITLE, DATASOURCECAMPAIGN, STATIONGROUPNAME, STATIONNAME, BookedMonth AS Month, TYPEDESCRIPTION, OffAirType, 'OffAir' as SpotType
        ,CREATEDDATETIME, SALESEXECNAME, SALESGROUPNAME, CLIENTNAME, AGENCYNAME, AgencyAndClient, Spots, [Gross Value Billable], [Net Value Stn Profit]
        ,[Agency Commission Stn Profit],[Net Value Billable], [Vat Stn Profit], [Total Stn Profit],JCN,ORDERVERSIONNO
		,(CASE	WHEN DATEPART(DW,CREATEDDATETIME) = 6 THEN DATEADD(D,3,CONVERT(DATE,CREATEDDATETIME))
				WHEN DATEPART(DW,CREATEDDATETIME) = 7 THEN DATEADD(D,2,CONVERT(DATE,CREATEDDATETIME))
				ELSE DATEADD(D,1,CONVERT(DATE,CREATEDDATETIME))
		 END)
        FROM CCTRAFFICLIVE.dbo.VOffAirStationProfitByExecByOrderInclFree WITH (nolock)
        WHERE CREATEDDATETIME BETWEEN @StartDate AND @EndDate
) AS RefreshRun
--
END

GO
/****** Object:  StoredProcedure [dbo].[GreensRefresh]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[GreensRefresh] 
@StartDate DATE
AS
BEGIN
SET NOCOUNT ON;
-- If not set, set start date to 1st day of year
SET @StartDate = COALESCE(@StartDate,DATEADD(YY, DATEDIFF(YY, 0, GETDATE()), 0))
--
PRINT 'Refresh of RevenueStaging -   Started at ' + CONVERT(VARCHAR,GETDATE(),121)
EXEC dbo.GreensRefreshStaging @StartDate
PRINT 'Refresh of RevenueStaging - Completed at ' + CONVERT(VARCHAR,GETDATE(),121)
PRINT '--------------------------------------------------------------------------------------------------------------'
--
PRINT 'Removing all records from Revenue -   Started at ' + CONVERT(VARCHAR,GETDATE(),121)
DELETE FROM Revenue
PRINT 'Removing all records from Revenue - Completed at ' + CONVERT(VARCHAR,GETDATE(),121)
PRINT '--------------------------------------------------------------------------------------------------------------'
--	
PRINT 'Adding all Revenue Staging records into Revenue -   Started at ' + CONVERT(VARCHAR,GETDATE(),121)
INSERT INTO Revenue
SELECT * FROM RevenueStaging
PRINT 'Adding all Revenue Staging records into Revenue - Completed at ' + CONVERT(VARCHAR,GETDATE(),121)
PRINT '--------------------------------------------------------------------------------------------------------------'
PRINT 'Process completed'
------------------------------------------------------------------------------------------------
END
GO
/****** Object:  StoredProcedure [dbo].[GreensRefreshNextYear]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[GreensRefreshNextYear] 
AS
BEGIN
SET NOCOUNT ON;
DECLARE @StartDate DATE
SET @StartDate = DATEADD(YYYY,1,(SELECT MIN(month) FROM Revenue))
PRINT @StartDate
PRINT 'Refresh of RevenueNextYearStaging -   Started at ' + CONVERT(VARCHAR,GETDATE(),121)
EXEC dbo.GreensRefreshNextYearStaging @StartDate
PRINT 'Refresh of RevenueNextYearStaging - Completed at ' + CONVERT(VARCHAR,GETDATE(),121)
PRINT '--------------------------------------------------------------------------------------------------------------'
--
PRINT 'Removing all records from RevenueNextYear -   Started at ' + CONVERT(VARCHAR,GETDATE(),121)
DELETE FROM RevenueNextYear
PRINT 'Removing all records from RevenueNextYear - Completed at ' + CONVERT(VARCHAR,GETDATE(),121)
PRINT '--------------------------------------------------------------------------------------------------------------'
--	
PRINT 'Adding all RevenueNextYearStaging records into RevenueStaging -   Started at ' + CONVERT(VARCHAR,GETDATE(),121)
INSERT INTO RevenueNextYear
SELECT * FROM RevenueNextYearStaging
PRINT 'Adding all RevenueNextYearStaging records into RevenueStaging - Completed at ' + CONVERT(VARCHAR,GETDATE(),121)
PRINT '--------------------------------------------------------------------------------------------------------------'
PRINT 'Process completed'
------------------------------------------------------------------------------------------------
END
GO
/****** Object:  StoredProcedure [dbo].[GreensRefreshNextYearStaging]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GreensRefreshNextYearStaging] 
@StartDate Date
AS
BEGIN
SET NOCOUNT ON;
DECLARE @EndDate Date
-- Set start date to beginning of month and end date to end of 11th month
SET @StartDate = dateadd(dd,-(day(@StartDate)-1),@StartDate)
SET @EndDate = CONVERT(date,dateadd(s,-1,dateadd(mm,datediff(m,0,dateadd(m,11,@StartDate))+1,0)))
-- Clear down
DELETE FROM Greens.dbo.RevenueNextYearStaging
-- Build Refreshed Revenue
INSERT INTO Greens.dbo.RevenueNextYearStaging SELECT * FROM (
SELECT 'Revenue' as Category, ORDERID, IMPORTED, ORDERTITLE, DATASOURCECAMPAIGN, STATIONGROUPNAME, STATIONNAME AS Station, BookedMonth AS Month, [CAMPAIGN TYPE],
        ACTIVITYDESCRIPTION AS 'Cost Type', SALESEXECNAME, CASE WHEN SALESGROUPNAME = 'Global Sales' OR SALESGROUPNAME = 'Non Contracted Agency' THEN GlobalTeam ELSE SALESGROUPNAME END as SALESGROUPNAME, CLIENTNAME, CLIENTID, AGENCYNAME, AgencyAndClient, AGENCYCRN, CLIENTCRN, EXTERNALREF,SPOTTYPEDESCRIPTION,Spots, [Gross Value], [Net Value],
        [Agency Commission] , [Net Value Billable], Vat, Total,0 AS Budget, 0 as ExecTarget, 0 as TeamTarget, [Net Value] as [Net Value Stn Profit],JCN,ORDERVERSIONNO, CREATEDDATETIME,RevMap,  RevStreamName,   RevStreamGroupName,  RevSourceName, GlobalTeam, BARTERPERCENT, BarterDiff, SourceCompanyName, Assisted
FROM TVREPORTS.dbo.VMappedAirtimeRev WITH (nolock)
WHERE (BookedMonth >= @StartDate AND BookedMonth < @EndDate)
------------------------------------------------------
Union
SELECT 'Revenue' as Category, ORDERID, IMPORTED, ORDERTITLE, DATASOURCECAMPAIGN, STATIONGROUPNAME, STATIONNAME, BookedMonth AS Month, TYPEDESCRIPTION, OffAirType,
SALESEXECNAME,CASE WHEN SALESGROUPNAME = 'Global Sales' OR SALESGROUPNAME = 'Non Contracted Agency' THEN GlobalTeam ELSE SALESGROUPNAME END as SALESGROUPNAME,  CLIENTNAME, CLIENTID, AGENCYNAME, AgencyAndClient, AGENCYCRN, CLIENTCRN,EXTERNALREF, 'OffAir' as SPOTTYPEDESCRIPTION, Spots, [Gross Value Billable], 0 as [Net Value],
[Agency Commission Stn Profit],[Net Value Billable], [Vat Stn Profit], [Total Stn Profit],0 AS Budget, 0 as ExecTarget, 0 as TeamTarget,[Net Value Stn Profit],JCN,ORDERVERSIONNO, CREATEDDATETIME,RevMap,  RevStreamName,   RevStreamGroupName,  RevSourceName, GlobalTeam, BARTERPERCENT, BarterDiff, SourceCompanyName, Assisted
FROM TVREPORTS.dbo.VMappedOARev WITH (nolock)
WHERE (BookedMonth >= @StartDate AND BookedMonth < @EndDate)
------------------------------------------------------
Union
SELECT 'Team Target' as Category, 0 as orderid, TT.TargetMonth as imported, 'Team Target' as ordertitle, 'Team Target' as DATASOURCECAMPAIGN, SG.SALESGROUPNAME as STATIONGROUPNAME, SG.SALESGROUPNAME as Station,TT.TargetMonth, 'Team Target' as [CAMPAIGN TYPE], 'Team Target' as [Cost Type], 'Team Target' as SALESEXECNAME, SG.SALESGROUPNAME, 'Team Target' AS CLIENTNAME, 0 AS CLIENTID, 'Team Target' AS AGENCYNAME, 'Team Target' as AgencyAndClient, 'Team Target' as AGENCYCRN, 'Team Target' as CLIENTCRN, 'Team Target' as EXTERNALREF, 'Team Target' as SPOTTYPEDESCRIPTION,0 as Spots, 0 as [Gross Value], 0 as [Net Value], 0 as [Agency Commission], 0 as [Net Value Billable], 0 as Vat, 0 as Total,0 AS Budget,
0 as ExecTarget, TT.Amount as TeamTarget, 0 as [Net Value Stn Profit],'Team Target' as JCN, 0 as ORDERVERSIONNO, TT.TargetMonth as CREATEDDATETIME, 'Team Target' as RevMap, RS.RevStreamName, RSG.RevStreamGroupName, RS1.RevSourceName, SG.SALESGROUPNAME, 1 AS BARTERPERCENT,
0 as BarterDiff, SourceCompanyName, 'Team Target' as Assisted
FROM TVREPORTS.dbo.RPTeamTargets AS TT INNER JOIN
TVREPORTS.dbo.RPRevStream AS RS ON TT.RevStreamID = RS.RevStreamID INNER JOIN
TVREPORTS.dbo.RPRevStreamGroup AS RSG ON RS.RevStreamGroupID = RSG.RevStreamGroupID INNER JOIN
TVREPORTS.dbo.RPRevSource AS RS1 ON RSG.RevSourceID = RS1.RevSourceID INNER JOIN
CCTRAFFICLIVE.dbo.RASALESGROUP AS SG ON TT.SalesGroupID = SG.SALESGROUPID INNER JOIN TVREPORTS.dbo.RPSourceCompany AS RPSC ON RSG.SourceCompanyID = RPSC.SourceCompanyID
WHERE (TT.TargetMonth  >= @StartDate AND TT.TargetMonth < @EndDate)
------------------------------------------------------
Union
SELECT 'Exec Target' as Category, 0 as orderid, ET.TargetMonth as imported, 'Exec Target' as ordertitle, 'Exec Target' as DATASOURCECAMPAIGN, SG.SALESGROUPNAME as STATIONGROUPNAME, SG.SALESGROUPNAME as Station,ET.TargetMonth, 'Exec Target' as [CAMPAIGN TYPE], 'Exec Target' as [Cost Type], SE.SALESEXECNAME, SG.SALESGROUPNAME, 'Exec Target' AS CLIENTNAME, 0 AS CLIENTID, 'Exec Target' AS AGENCYNAME, 'Exec Target' as AgencyAndClient, 'Exec Target' as AGENCYCRN, 'Exec Target' as CLIENTCRN, 'Exec Target' as EXTERNALREF, 'Exec Target' as SPOTTYPEDESCRIPTION,0 as Spots, 0 as [Gross Value],   0 as [Net Value], 0 as [Agency Commission], 0 as [Net Value Billable], 0 as Vat, 0 as Total,0 AS Budget, ET.Amount as ExecTarget, 0 as TeamTarget, 0 as [Net Value Stn Profit],'Exec Target' as JCN, 0 as ORDERVERSIONNO, ET.TargetMonth as CREATEDDATETIME,
'Exec Target' as RevMap, 'Local' AS RevStreamName, 'Local' AS RevStreamGroupName, 'Local' AS RevSourceName, SG.SALESGROUPNAME, 1 AS BARTERPERCENT, 0 as BarterDiff, 'CCP' as SourceCompanyName, 'Exec Target' as Assisted
FROM  CCTRAFFICLIVE.dbo.RASALESEXECS AS SE LEFT JOIN
CCTRAFFICLIVE.dbo.RASALESGROUP AS SG ON SE.SALESGROUPID = SG.SALESGROUPID JOIN
TVREPORTS.dbo.RPExecTargets AS ET ON SE.SALESEXECID = ET.SalesExecID
WHERE (ET.TargetMonth  >= @StartDate AND ET.TargetMonth < @EndDate)
------------------------------------------------------
Union
SELECT 'Budget' AS Category, 0 AS OrderID, SB.BudgetMonth AS Imported, 'Stn Budget' AS OrderTitle, 'Stn Budget' AS DataSourceCampaign, SG.STATIONGROUPNAME, SG.STATIONGROUPNAME AS Station,
SB.BudgetMonth, 'Stn Budget' AS [CAMPAIGN TYPE], 'Stn Budget' AS [Cost Type], 'Stn Budget' AS SALESEXECNAME, 'Stn Budget' AS SALESGROUPNAME, 'Stn Budget' AS ClientName, 0 AS ClientID,
'Stn Budget' AS AGENCYNAME, 'Stn Budget' AS AgencyAndClient, 'Stn Budget' AS AGENCYCRN, 'Stn Budget' AS CLIENTCRN, 'Stn Budget' AS EXTERNALREF, 'Stn Budget' AS SPOTTYPEDESCRIPTION, 0 AS Spots,
0 AS [Gross Value], 0 AS [Net Value], 0 AS [Agency Commission], 0 AS [Net Value Billable], 0 AS Vat, 0 AS Total, SUM(SB.Amount) AS Budget, 0 AS ExecTarget, 0 AS TeamTarget, 0 as [Net Value Stn Profit], 'Stn Budget' AS JCN,
0 AS ORDERVERSIONNO, SB.BudgetMonth AS CREATEDDATETIME, 'Stn Budget' AS RevMap, RS.RevStreamName, RSG.RevStreamGroupName,
RS1.RevSourceName, 'Stn Budget' AS Expr1, 1 AS BARTERPERCENT, 0 AS BarterDiff, SourceCompanyName, 'Stn Budget' as Assisted
FROM TVREPORTS.dbo.RPStnBudgets AS SB INNER JOIN
CCTRAFFICLIVE.dbo.RASTATIONGROUPS AS SG ON SB.StationGroupID = SG.STATIONGROUPID INNER JOIN
TVREPORTS.dbo.RPRevStream AS RS ON SB.RevStreamID = RS.RevStreamID INNER JOIN
TVREPORTS.dbo.RPRevStreamGroup AS RSG ON RS.RevStreamGroupID = RSG.RevStreamGroupID INNER JOIN
TVREPORTS.dbo.RPRevSource AS RS1 ON RSG.RevSourceID = RS1.RevSourceID INNER JOIN TVREPORTS.dbo.RPSourceCompany AS RPSC ON RSG.SourceCompanyID = RPSC.SourceCompanyID
WHERE (SB.BudgetMonth  >= @StartDate AND SB.BudgetMonth < @EndDate)
GROUP BY SG.STATIONGROUPNAME, SB.BudgetMonth, RS.RevStreamName, RSG.RevStreamGroupName, RS1.RevSourceName, SourceCompanyName
------------------------------------------------------
 ) AS RefreshRun
END
-----
GO
/****** Object:  StoredProcedure [dbo].[GreensRefreshPastYears]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GreensRefreshPastYears] 
@StartDate Date
AS
BEGIN
SET NOCOUNT ON;
DECLARE @EndDate Date
-- Set start date to beginning of month and end date to last month before current financial year
-- If start date is null, set start date to 1st of January 3 years ago
SET @StartDate = COALESCE(@StartDate,DATEADD(YY, DATEDIFF(YY, 0, GETDATE()) - 3, 0))
SET @StartDate = dateadd(dd,-(day(@StartDate)-1),@StartDate)
SET @EndDate = DATEADD(M,-1,(SELECT MIN(month) FROM Revenue))
-- Clear down
DELETE FROM Greens.dbo.RevenuePastYears
-- Build Refreshed Revenue
INSERT INTO Greens.dbo.RevenuePastYears SELECT * FROM (
SELECT 'Revenue' as Category, ORDERID, IMPORTED, ORDERTITLE, DATASOURCECAMPAIGN, STATIONGROUPNAME, STATIONNAME AS Station, BookedMonth AS Month, [CAMPAIGN TYPE],
        ACTIVITYDESCRIPTION AS 'Cost Type', SALESEXECNAME, CASE WHEN SALESGROUPNAME = 'Global Sales' OR SALESGROUPNAME = 'Non Contracted Agency' THEN GlobalTeam ELSE SALESGROUPNAME END as SALESGROUPNAME, CLIENTNAME, CLIENTID, AGENCYNAME, AgencyAndClient, AGENCYCRN, CLIENTCRN, EXTERNALREF,SPOTTYPEDESCRIPTION,Spots, [Gross Value], [Net Value],
        [Agency Commission] , [Net Value Billable], Vat, Total,0 AS Budget, 0 as ExecTarget, 0 as TeamTarget, [Net Value] as [Net Value Stn Profit],JCN,ORDERVERSIONNO, CREATEDDATETIME,RevMap,  RevStreamName,   RevStreamGroupName,  RevSourceName, GlobalTeam, BARTERPERCENT, BarterDiff, SourceCompanyName, Assisted
FROM TVREPORTS.dbo.VMappedAirtimeRev WITH (nolock)
WHERE (BookedMonth >= @StartDate AND BookedMonth <= @EndDate)
------------------------------------------------------
Union
SELECT 'Revenue' as Category, ORDERID, IMPORTED, ORDERTITLE, DATASOURCECAMPAIGN, STATIONGROUPNAME, STATIONNAME, BookedMonth AS Month, TYPEDESCRIPTION, OffAirType,
SALESEXECNAME,CASE WHEN SALESGROUPNAME = 'Global Sales' OR SALESGROUPNAME = 'Non Contracted Agency' THEN GlobalTeam ELSE SALESGROUPNAME END as SALESGROUPNAME,  CLIENTNAME, CLIENTID, AGENCYNAME, AgencyAndClient, AGENCYCRN, CLIENTCRN,EXTERNALREF, 'OffAir' as SPOTTYPEDESCRIPTION, Spots, [Gross Value Billable], 0 as [Net Value],
[Agency Commission Stn Profit],[Net Value Billable], [Vat Stn Profit], [Total Stn Profit],0 AS Budget, 0 as ExecTarget, 0 as TeamTarget,[Net Value Stn Profit],JCN,ORDERVERSIONNO, CREATEDDATETIME,RevMap,  RevStreamName,   RevStreamGroupName,  RevSourceName, GlobalTeam, BARTERPERCENT, BarterDiff, SourceCompanyName, Assisted
FROM TVREPORTS.dbo.VMappedOARev WITH (nolock)
WHERE (BookedMonth >= @StartDate AND BookedMonth <= @EndDate)
------------------------------------------------------
Union
SELECT 'Team Target' as Category, 0 as orderid, TT.TargetMonth as imported, 'Team Target' as ordertitle, 'Team Target' as DATASOURCECAMPAIGN, SG.SALESGROUPNAME as STATIONGROUPNAME, SG.SALESGROUPNAME as Station,TT.TargetMonth, 'Team Target' as [CAMPAIGN TYPE], 'Team Target' as [Cost Type], 'Team Target' as SALESEXECNAME, SG.SALESGROUPNAME, 'Team Target' AS CLIENTNAME, 0 AS CLIENTID, 'Team Target' AS AGENCYNAME, 'Team Target' as AgencyAndClient, 'Team Target' as AGENCYCRN, 'Team Target' as CLIENTCRN, 'Team Target' as EXTERNALREF, 'Team Target' as SPOTTYPEDESCRIPTION,0 as Spots, 0 as [Gross Value], 0 as [Net Value], 0 as [Agency Commission], 0 as [Net Value Billable], 0 as Vat, 0 as Total,0 AS Budget,
0 as ExecTarget, TT.Amount as TeamTarget, 0 as [Net Value Stn Profit],'Team Target' as JCN, 0 as ORDERVERSIONNO, TT.TargetMonth as CREATEDDATETIME, 'Team Target' as RevMap, RS.RevStreamName, RSG.RevStreamGroupName, RS1.RevSourceName, SG.SALESGROUPNAME, 1 AS BARTERPERCENT,
0 as BarterDiff, SourceCompanyName, 'Team Target' as Assisted
FROM TVREPORTS.dbo.RPTeamTargets AS TT INNER JOIN
TVREPORTS.dbo.RPRevStream AS RS ON TT.RevStreamID = RS.RevStreamID INNER JOIN
TVREPORTS.dbo.RPRevStreamGroup AS RSG ON RS.RevStreamGroupID = RSG.RevStreamGroupID INNER JOIN
TVREPORTS.dbo.RPRevSource AS RS1 ON RSG.RevSourceID = RS1.RevSourceID INNER JOIN
CCTRAFFICLIVE.dbo.RASALESGROUP AS SG ON TT.SalesGroupID = SG.SALESGROUPID INNER JOIN TVREPORTS.dbo.RPSourceCompany AS RPSC ON RSG.SourceCompanyID = RPSC.SourceCompanyID
WHERE (TT.TargetMonth  >= @StartDate AND TT.TargetMonth <= @EndDate)
------------------------------------------------------
Union
SELECT 'Exec Target' as Category, 0 as orderid, ET.TargetMonth as imported, 'Exec Target' as ordertitle, 'Exec Target' as DATASOURCECAMPAIGN, SG.SALESGROUPNAME as STATIONGROUPNAME, SG.SALESGROUPNAME as Station,ET.TargetMonth, 'Exec Target' as [CAMPAIGN TYPE], 'Exec Target' as [Cost Type], SE.SALESEXECNAME, SG.SALESGROUPNAME, 'Exec Target' AS CLIENTNAME, 0 AS CLIENTID, 'Exec Target' AS AGENCYNAME, 'Exec Target' as AgencyAndClient, 'Exec Target' as AGENCYCRN, 'Exec Target' as CLIENTCRN, 'Exec Target' as EXTERNALREF, 'Exec Target' as SPOTTYPEDESCRIPTION,0 as Spots, 0 as [Gross Value],   0 as [Net Value], 0 as [Agency Commission], 0 as [Net Value Billable], 0 as Vat, 0 as Total,0 AS Budget, ET.Amount as ExecTarget, 0 as TeamTarget, 0 as [Net Value Stn Profit],'Exec Target' as JCN, 0 as ORDERVERSIONNO, ET.TargetMonth as CREATEDDATETIME,
'Exec Target' as RevMap, 'Local' AS RevStreamName, 'Local' AS RevStreamGroupName, 'Local' AS RevSourceName, SG.SALESGROUPNAME, 1 AS BARTERPERCENT, 0 as BarterDiff, 'CCP' as SourceCompanyName, 'Exec Target' as Assisted
FROM  CCTRAFFICLIVE.dbo.RASALESEXECS AS SE LEFT JOIN
CCTRAFFICLIVE.dbo.RASALESGROUP AS SG ON SE.SALESGROUPID = SG.SALESGROUPID JOIN
TVREPORTS.dbo.RPExecTargets AS ET ON SE.SALESEXECID = ET.SalesExecID
WHERE (ET.TargetMonth  >= @StartDate AND ET.TargetMonth <= @EndDate)
------------------------------------------------------
Union
SELECT 'Budget' AS Category, 0 AS OrderID, SB.BudgetMonth AS Imported, 'Stn Budget' AS OrderTitle, 'Stn Budget' AS DataSourceCampaign, SG.STATIONGROUPNAME, SG.STATIONGROUPNAME AS Station,
SB.BudgetMonth, 'Stn Budget' AS [CAMPAIGN TYPE], 'Stn Budget' AS [Cost Type], 'Stn Budget' AS SALESEXECNAME, 'Stn Budget' AS SALESGROUPNAME, 'Stn Budget' AS ClientName, 0 AS ClientID,
'Stn Budget' AS AGENCYNAME, 'Stn Budget' AS AgencyAndClient, 'Stn Budget' AS AGENCYCRN, 'Stn Budget' AS CLIENTCRN, 'Stn Budget' AS EXTERNALREF, 'Stn Budget' AS SPOTTYPEDESCRIPTION, 0 AS Spots,
0 AS [Gross Value], 0 AS [Net Value], 0 AS [Agency Commission], 0 AS [Net Value Billable], 0 AS Vat, 0 AS Total, SUM(SB.Amount) AS Budget, 0 AS ExecTarget, 0 AS TeamTarget, 0 as [Net Value Stn Profit], 'Stn Budget' AS JCN,
0 AS ORDERVERSIONNO, SB.BudgetMonth AS CREATEDDATETIME, 'Stn Budget' AS RevMap, RS.RevStreamName, RSG.RevStreamGroupName,
RS1.RevSourceName, 'Stn Budget' AS Expr1, 1 AS BARTERPERCENT, 0 AS BarterDiff, SourceCompanyName, 'Stn Budget' as Assisted
FROM TVREPORTS.dbo.RPStnBudgets AS SB INNER JOIN
CCTRAFFICLIVE.dbo.RASTATIONGROUPS AS SG ON SB.StationGroupID = SG.STATIONGROUPID INNER JOIN
TVREPORTS.dbo.RPRevStream AS RS ON SB.RevStreamID = RS.RevStreamID INNER JOIN
TVREPORTS.dbo.RPRevStreamGroup AS RSG ON RS.RevStreamGroupID = RSG.RevStreamGroupID INNER JOIN
TVREPORTS.dbo.RPRevSource AS RS1 ON RSG.RevSourceID = RS1.RevSourceID INNER JOIN TVREPORTS.dbo.RPSourceCompany AS RPSC ON RSG.SourceCompanyID = RPSC.SourceCompanyID
WHERE (SB.BudgetMonth  >= @StartDate AND SB.BudgetMonth <= @EndDate)
GROUP BY SG.STATIONGROUPNAME, SB.BudgetMonth, RS.RevStreamName, RSG.RevStreamGroupName, RS1.RevSourceName, SourceCompanyName
------------------------------------------------------
 ) AS RefreshRun
END
-----
GO
/****** Object:  StoredProcedure [dbo].[GreensRefreshStaging]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GreensRefreshStaging] 
@StartDate Date
AS
BEGIN
SET NOCOUNT ON;
DECLARE @EndDate Date
-- Set start date to beginning of month and end date to end of 11th month
SET @StartDate = dateadd(dd,-(day(@StartDate)-1),@StartDate)
SET @EndDate = CONVERT(date,dateadd(s,-1,dateadd(mm,datediff(m,0,dateadd(m,11,@StartDate))+1,0)))
-- Clear down
DELETE FROM Greens.dbo.RevenueStaging
-- Build Refreshed Revenue
INSERT INTO Greens.dbo.RevenueStaging SELECT * FROM (
SELECT 'Revenue' as Category, ORDERID, IMPORTED, ORDERTITLE, DATASOURCECAMPAIGN, STATIONGROUPNAME, STATIONNAME AS Station, BookedMonth AS Month, [CAMPAIGN TYPE],
        ACTIVITYDESCRIPTION AS 'Cost Type', SALESEXECNAME, CASE WHEN SALESGROUPNAME = 'Global Sales' OR SALESGROUPNAME = 'Non Contracted Agency' THEN GlobalTeam ELSE SALESGROUPNAME END as SALESGROUPNAME, CLIENTNAME, CLIENTID, AGENCYNAME, AgencyAndClient, AGENCYCRN, CLIENTCRN, EXTERNALREF,SPOTTYPEDESCRIPTION,Spots, [Gross Value], [Net Value],
        [Agency Commission] , [Net Value Billable], Vat, Total,0 AS Budget, 0 as ExecTarget, 0 as TeamTarget, [Net Value] as [Net Value Stn Profit],JCN,ORDERVERSIONNO, CREATEDDATETIME,RevMap,  RevStreamName,   RevStreamGroupName,  RevSourceName, GlobalTeam, BARTERPERCENT, BarterDiff, SourceCompanyName, Assisted
FROM TVREPORTS.dbo.VMappedAirtimeRev WITH (nolock)
WHERE (BookedMonth >= @StartDate AND BookedMonth < @EndDate)
------------------------------------------------------
Union
SELECT 'Revenue' as Category, ORDERID, IMPORTED, ORDERTITLE, DATASOURCECAMPAIGN, STATIONGROUPNAME, STATIONNAME, BookedMonth AS Month, TYPEDESCRIPTION, OffAirType,
SALESEXECNAME,CASE WHEN SALESGROUPNAME = 'Global Sales' OR SALESGROUPNAME = 'Non Contracted Agency' THEN GlobalTeam ELSE SALESGROUPNAME END as SALESGROUPNAME,  CLIENTNAME, CLIENTID, AGENCYNAME, AgencyAndClient, AGENCYCRN, CLIENTCRN,EXTERNALREF, 'OffAir' as SPOTTYPEDESCRIPTION, Spots, [Gross Value Billable], 0 as [Net Value],
[Agency Commission Stn Profit],[Net Value Billable], [Vat Stn Profit], [Total Stn Profit],0 AS Budget, 0 as ExecTarget, 0 as TeamTarget,[Net Value Stn Profit],JCN,ORDERVERSIONNO, CREATEDDATETIME,RevMap,  RevStreamName,   RevStreamGroupName,  RevSourceName, GlobalTeam, BARTERPERCENT, BarterDiff, SourceCompanyName, Assisted
FROM TVREPORTS.dbo.VMappedOARev WITH (nolock)
WHERE (BookedMonth >= @StartDate AND BookedMonth < @EndDate)
------------------------------------------------------
Union
SELECT 'Team Target' as Category, 0 as orderid, TT.TargetMonth as imported, 'Team Target' as ordertitle, 'Team Target' as DATASOURCECAMPAIGN, SG.SALESGROUPNAME as STATIONGROUPNAME, SG.SALESGROUPNAME as Station,TT.TargetMonth, 'Team Target' as [CAMPAIGN TYPE], 'Team Target' as [Cost Type], 'Team Target' as SALESEXECNAME, SG.SALESGROUPNAME, 'Team Target' AS CLIENTNAME, 0 AS CLIENTID, 'Team Target' AS AGENCYNAME, 'Team Target' as AgencyAndClient, 'Team Target' as AGENCYCRN, 'Team Target' as CLIENTCRN, 'Team Target' as EXTERNALREF, 'Team Target' as SPOTTYPEDESCRIPTION,0 as Spots, 0 as [Gross Value], 0 as [Net Value], 0 as [Agency Commission], 0 as [Net Value Billable], 0 as Vat, 0 as Total,0 AS Budget,
0 as ExecTarget, TT.Amount as TeamTarget, 0 as [Net Value Stn Profit],'Team Target' as JCN, 0 as ORDERVERSIONNO, TT.TargetMonth as CREATEDDATETIME, 'Team Target' as RevMap, RS.RevStreamName, RSG.RevStreamGroupName, RS1.RevSourceName, SG.SALESGROUPNAME, 1 AS BARTERPERCENT,
0 as BarterDiff, SourceCompanyName, 'Team Target' as Assisted
FROM TVREPORTS.dbo.RPTeamTargets AS TT INNER JOIN
TVREPORTS.dbo.RPRevStream AS RS ON TT.RevStreamID = RS.RevStreamID INNER JOIN
TVREPORTS.dbo.RPRevStreamGroup AS RSG ON RS.RevStreamGroupID = RSG.RevStreamGroupID INNER JOIN
TVREPORTS.dbo.RPRevSource AS RS1 ON RSG.RevSourceID = RS1.RevSourceID INNER JOIN
CCTRAFFICLIVE.dbo.RASALESGROUP AS SG ON TT.SalesGroupID = SG.SALESGROUPID INNER JOIN TVREPORTS.dbo.RPSourceCompany AS RPSC ON RSG.SourceCompanyID = RPSC.SourceCompanyID
WHERE (TT.TargetMonth  >= @StartDate AND TT.TargetMonth < @EndDate)
------------------------------------------------------
Union
SELECT 'Exec Target' as Category, 0 as orderid, ET.TargetMonth as imported, 'Exec Target' as ordertitle, 'Exec Target' as DATASOURCECAMPAIGN, SG.SALESGROUPNAME as STATIONGROUPNAME, SG.SALESGROUPNAME as Station,ET.TargetMonth, 'Exec Target' as [CAMPAIGN TYPE], 'Exec Target' as [Cost Type], SE.SALESEXECNAME, SG.SALESGROUPNAME, 'Exec Target' AS CLIENTNAME, 0 AS CLIENTID, 'Exec Target' AS AGENCYNAME, 'Exec Target' as AgencyAndClient, 'Exec Target' as AGENCYCRN, 'Exec Target' as CLIENTCRN, 'Exec Target' as EXTERNALREF, 'Exec Target' as SPOTTYPEDESCRIPTION,0 as Spots, 0 as [Gross Value],   0 as [Net Value], 0 as [Agency Commission], 0 as [Net Value Billable], 0 as Vat, 0 as Total,0 AS Budget, ET.Amount as ExecTarget, 0 as TeamTarget, 0 as [Net Value Stn Profit],'Exec Target' as JCN, 0 as ORDERVERSIONNO, ET.TargetMonth as CREATEDDATETIME,
'Exec Target' as RevMap, 'Local' AS RevStreamName, 'Local' AS RevStreamGroupName, 'Local' AS RevSourceName, SG.SALESGROUPNAME, 1 AS BARTERPERCENT, 0 as BarterDiff, 'CCP' as SourceCompanyName, 'Exec Target' as Assisted
FROM  CCTRAFFICLIVE.dbo.RASALESEXECS AS SE LEFT JOIN
CCTRAFFICLIVE.dbo.RASALESGROUP AS SG ON SE.SALESGROUPID = SG.SALESGROUPID JOIN
TVREPORTS.dbo.RPExecTargets AS ET ON SE.SALESEXECID = ET.SalesExecID
WHERE (ET.TargetMonth  >= @StartDate AND ET.TargetMonth < @EndDate)
------------------------------------------------------
Union
SELECT 'Budget' AS Category, 0 AS OrderID, SB.BudgetMonth AS Imported, 'Stn Budget' AS OrderTitle, 'Stn Budget' AS DataSourceCampaign, SG.STATIONGROUPNAME, SG.STATIONGROUPNAME AS Station,
SB.BudgetMonth, 'Stn Budget' AS [CAMPAIGN TYPE], 'Stn Budget' AS [Cost Type], 'Stn Budget' AS SALESEXECNAME, 'Stn Budget' AS SALESGROUPNAME, 'Stn Budget' AS ClientName, 0 AS ClientID,
'Stn Budget' AS AGENCYNAME, 'Stn Budget' AS AgencyAndClient, 'Stn Budget' AS AGENCYCRN, 'Stn Budget' AS CLIENTCRN, 'Stn Budget' AS EXTERNALREF, 'Stn Budget' AS SPOTTYPEDESCRIPTION, 0 AS Spots,
0 AS [Gross Value], 0 AS [Net Value], 0 AS [Agency Commission], 0 AS [Net Value Billable], 0 AS Vat, 0 AS Total, SUM(SB.Amount) AS Budget, 0 AS ExecTarget, 0 AS TeamTarget, 0 as [Net Value Stn Profit], 'Stn Budget' AS JCN,
0 AS ORDERVERSIONNO, SB.BudgetMonth AS CREATEDDATETIME, 'Stn Budget' AS RevMap, RS.RevStreamName, RSG.RevStreamGroupName,
RS1.RevSourceName, 'Stn Budget' AS Expr1, 1 AS BARTERPERCENT, 0 AS BarterDiff, SourceCompanyName, 'Stn Budget' as Assisted
FROM TVREPORTS.dbo.RPStnBudgets AS SB INNER JOIN
CCTRAFFICLIVE.dbo.RASTATIONGROUPS AS SG ON SB.StationGroupID = SG.STATIONGROUPID INNER JOIN
TVREPORTS.dbo.RPRevStream AS RS ON SB.RevStreamID = RS.RevStreamID INNER JOIN
TVREPORTS.dbo.RPRevStreamGroup AS RSG ON RS.RevStreamGroupID = RSG.RevStreamGroupID INNER JOIN
TVREPORTS.dbo.RPRevSource AS RS1 ON RSG.RevSourceID = RS1.RevSourceID INNER JOIN TVREPORTS.dbo.RPSourceCompany AS RPSC ON RSG.SourceCompanyID = RPSC.SourceCompanyID
WHERE (SB.BudgetMonth  >= @StartDate AND SB.BudgetMonth < @EndDate)
GROUP BY SG.STATIONGROUPNAME, SB.BudgetMonth, RS.RevStreamName, RSG.RevStreamGroupName, RS1.RevSourceName, SourceCompanyName
------------------------------------------------------
 ) AS RefreshRun
END
-----
GO
/****** Object:  StoredProcedure [dbo].[NCARevenueBreakdownDrilldown]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[NCARevenueBreakdownDrilldown] 

@SalesGroupName VARCHAR(500)
,@RevStreamGroupName VARCHAR(50)
,@RevStreamName VARCHAR(500)
,@Month Date
,@SalesExecName VARCHAR(128)
,@QuarterBreakdown INT
,@AssistedFlag CHAR(1)
AS
BEGIN
SET NOCOUNT ON;
--
SELECT	(CASE WHEN r.Assisted = 'CAW' THEN 'Assisted Executives' ELSE r.SALESEXECNAME END) AS 'SalesExecName'
		,r.CLIENTNAME AS 'ClientName'
		,r.DATASOURCECAMPAIGN AS 'CampaignID'
		,r.[CAMPAIGN TYPE] AS 'CampaignType'
		,r.[Cost Type] AS 'CostType'
		,r.Month
		,SUM(r.[Net Value Billable]) AS NetValueBillable
		,SUM(r.[Net Value Stn Profit]) AS NetValueStnProfit
		,(SUM(r.[Net Value Billable]) - SUM(r.[Net Value Stn Profit])) AS 'Costs'
FROM Revenue r
WHERE	((CASE WHEN r.Assisted = 'CAW' THEN 'Assisted Executives' ELSE r.SALESEXECNAME END) = @SalesExecName OR @SalesExecName IS NULL)
		AND (r.SALESGROUPNAME IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@SalesGroupName,',')) OR @SalesGroupName = '' OR @SalesGroupName IS NULL)
		--
		AND ((r.RevStreamGroupName = @RevStreamGroupName) OR @RevStreamGroupName IS null)
		AND ((r.RevStreamName IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@RevStreamName,','))) OR @RevStreamName IS NULL)
		AND (r.Month = @Month
			OR r.Month = CASE WHEN @QuarterBreakdown = 1 THEN DATEADD(m,1,@Month) END
			OR r.Month = CASE WHEN @QuarterBreakdown = 1 THEN DATEADD(m,2,@Month) END
			OR @Month IS NULL)
		AND (@AssistedFlag = (CASE WHEN r.Assisted = 'CAW' THEN 'Y' ELSE 'N' END) OR @AssistedFlag IS NULL)
		-- Added filters
		-- Always agency
		AND r.RevSourceName = 'Agency'
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
		AND r.Category = 'Revenue'
GROUP BY (CASE WHEN r.Assisted = 'CAW' THEN 'Assisted Executives' ELSE r.SALESEXECNAME END)
		,r.CLIENTNAME
		,r.DATASOURCECAMPAIGN
		,r.[CAMPAIGN TYPE]
		,r.[Cost Type]
		,r.Month
END
GO
/****** Object:  StoredProcedure [dbo].[NCARevenueBreakdownDrilldownLastYear]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[NCARevenueBreakdownDrilldownLastYear] 

@SalesGroupName VARCHAR(500)
,@RevStreamGroupName VARCHAR(50)
,@RevStreamName VARCHAR(500)
,@Month Date
,@SalesExecName VARCHAR(128)
,@QuarterBreakdown INT
,@AssistedFlag CHAR(1)
AS
BEGIN
SET NOCOUNT ON;
--
SELECT	(CASE WHEN r.Assisted = 'CAW' THEN 'Assisted Executives' ELSE r.SALESEXECNAME END) AS 'SalesExecName'
		,r.CLIENTNAME AS 'ClientName'
		,r.DATASOURCECAMPAIGN AS 'CampaignID'
		,r.[CAMPAIGN TYPE] AS 'CampaignType'
		,r.[Cost Type] AS 'CostType'
		,r.Month
		,SUM(r.[Net Value Billable]) AS NetValueBillable
		,SUM(r.[Net Value Stn Profit]) AS NetValueStnProfit
		,(SUM(r.[Net Value Billable]) - SUM(r.[Net Value Stn Profit])) AS 'Costs'
FROM v_RevenueLastYear r
WHERE	((CASE WHEN r.Assisted = 'CAW' THEN 'Assisted Executives' ELSE r.SALESEXECNAME END) = @SalesExecName OR @SalesExecName IS NULL)
		AND (r.SALESGROUPNAME IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@SalesGroupName,',')) OR @SalesGroupName = '' OR @SalesGroupName IS NULL)
		--
		AND ((r.RevStreamGroupName = @RevStreamGroupName) OR @RevStreamGroupName IS null)
		AND ((r.RevStreamName IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@RevStreamName,','))) OR @RevStreamName IS NULL)
		AND (r.Month = @Month
			OR r.Month = CASE WHEN @QuarterBreakdown = 1 THEN DATEADD(m,1,@Month) END
			OR r.Month = CASE WHEN @QuarterBreakdown = 1 THEN DATEADD(m,2,@Month) END
			OR @Month IS NULL)
		AND (@AssistedFlag = (CASE WHEN r.Assisted = 'CAW' THEN 'Y' ELSE 'N' END) OR @AssistedFlag IS NULL)
		-- Added filters
		-- Always agency
		AND r.RevSourceName = 'Agency'
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
		AND r.Category = 'Revenue'
GROUP BY (CASE WHEN r.Assisted = 'CAW' THEN 'Assisted Executives' ELSE r.SALESEXECNAME END)
		,r.CLIENTNAME
		,r.DATASOURCECAMPAIGN
		,r.[CAMPAIGN TYPE]
		,r.[Cost Type]
		,r.Month
END
GO
/****** Object:  StoredProcedure [dbo].[NCARevenueBreakdownDrilldownNextYear]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[NCARevenueBreakdownDrilldownNextYear] 

@SalesGroupName VARCHAR(500)
,@RevStreamGroupName VARCHAR(50)
,@RevStreamName VARCHAR(500)
,@Month Date
,@SalesExecName VARCHAR(128)
,@QuarterBreakdown INT
,@AssistedFlag CHAR(1)
AS
BEGIN
SET NOCOUNT ON;
--
SELECT	(CASE WHEN r.Assisted = 'CAW' THEN 'Assisted Executives' ELSE r.SALESEXECNAME END) AS 'SalesExecName'
		,r.CLIENTNAME AS 'ClientName'
		,r.DATASOURCECAMPAIGN AS 'CampaignID'
		,r.[CAMPAIGN TYPE] AS 'CampaignType'
		,r.[Cost Type] AS 'CostType'
		,r.Month
		,SUM(r.[Net Value Billable]) AS NetValueBillable
		,SUM(r.[Net Value Stn Profit]) AS NetValueStnProfit
		,(SUM(r.[Net Value Billable]) - SUM(r.[Net Value Stn Profit])) AS 'Costs'
FROM RevenueNextYear r
WHERE	((CASE WHEN r.Assisted = 'CAW' THEN 'Assisted Executives' ELSE r.SALESEXECNAME END) = @SalesExecName OR @SalesExecName IS NULL)
		AND (r.SALESGROUPNAME IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@SalesGroupName,',')) OR @SalesGroupName = '' OR @SalesGroupName IS NULL)
		--
		AND ((r.RevStreamGroupName = @RevStreamGroupName) OR @RevStreamGroupName IS null)
		AND ((r.RevStreamName IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@RevStreamName,','))) OR @RevStreamName IS NULL)
		AND (r.Month = @Month
			OR r.Month = CASE WHEN @QuarterBreakdown = 1 THEN DATEADD(m,1,@Month) END
			OR r.Month = CASE WHEN @QuarterBreakdown = 1 THEN DATEADD(m,2,@Month) END
			OR @Month IS NULL)
		AND (@AssistedFlag = (CASE WHEN r.Assisted = 'CAW' THEN 'Y' ELSE 'N' END) OR @AssistedFlag IS NULL)
		-- Added filters
		-- Always agency
		AND r.RevSourceName = 'Agency'
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
		AND r.Category = 'Revenue'
GROUP BY (CASE WHEN r.Assisted = 'CAW' THEN 'Assisted Executives' ELSE r.SALESEXECNAME END)
		,r.CLIENTNAME
		,r.DATASOURCECAMPAIGN
		,r.[CAMPAIGN TYPE]
		,r.[Cost Type]
		,r.Month
END
GO
/****** Object:  StoredProcedure [dbo].[RevenueBreakdown]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[RevenueBreakdown] 
@RevenueStartMonth Date
,@SalesGroupName VARCHAR(256)
AS
BEGIN
SET NOCOUNT ON;
--
SELECT r1.MappingStream	
	,v1.Month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
	,SUM(v1.NetValueStnProfit) AS NetValueStnProfit
	,DATEDIFF(m,@RevenueStartMonth,v1.MONTH) + 1 AS MonthNo
	,(SELECT MIN(r2.OrderNo) FROM ReferenceStreamMapping r2 WHERE
	r2.MappingStream = r1.MappingStream 
	AND r2.MappedStreamName = r1.MappedStreamName
	AND r2.MappingType = 'Revenue') AS OrderNo
FROM ReferenceStreamMapping r1
LEFT OUTER JOIN v_SourceCCPTL v1
				ON v1.RevSourceName = r1.RevSourceName
				AND v1.RevStreamGroupName = r1.RevStreamGroupName
				--  Blank text allows selection of all
				AND (v1.RevStreamName = r1.RevStreamName OR r1.RevStreamName = '')
				AND v1.SalesGroupName IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@SalesGroupName,','))
WHERE r1.MappingType = 'Revenue'
GROUP BY r1.MappingStream 
	,v1.month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
END
GO
/****** Object:  StoredProcedure [dbo].[RevenueBreakdownLastYear]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[RevenueBreakdownLastYear] 
@RevenueStartMonth Date
,@SalesGroupName VARCHAR(256)
AS
BEGIN
SET NOCOUNT ON;
--
SELECT r1.MappingStream	
	,v1.Month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
	,SUM(v1.NetValueStnProfit) AS NetValueStnProfit
	,DATEDIFF(m,@RevenueStartMonth,v1.MONTH) + 1 AS MonthNo
	,(SELECT MIN(r2.OrderNo) FROM ReferenceStreamMapping r2 WHERE
	r2.MappingStream = r1.MappingStream 
	AND r2.MappedStreamName = r1.MappedStreamName
	AND r2.MappingType = 'Revenue') AS OrderNo
FROM ReferenceStreamMapping r1
LEFT OUTER JOIN v_SourceCCPTLLastYear v1
				ON v1.RevSourceName = r1.RevSourceName
				AND v1.RevStreamGroupName = r1.RevStreamGroupName
				--  Blank text allows selection of all
				AND (v1.RevStreamName = r1.RevStreamName OR r1.RevStreamName = '')
				AND v1.SalesGroupName IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@SalesGroupName,','))
WHERE r1.MappingType = 'Revenue'
GROUP BY r1.MappingStream 
	,v1.month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
END
GO
/****** Object:  StoredProcedure [dbo].[RevenueBreakdownMonth]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[RevenueBreakdownMonth] 
@Month Date
,@MonthSpan INT
,@SalesGroupsInclude VARCHAR(500)
AS
BEGIN
SET NOCOUNT ON;
--
SELECT	v1.SalesGroupName 
	,r1.MappingStream	
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
	,SUM(v1.NetValueStnProfit) AS NetValueStnProfit
	,(SELECT MIN(r2.OrderNo) FROM ReferenceStreamMapping r2 WHERE
	r2.MappingStream = r1.MappingStream
	AND r2.MappedStreamName = r1.MappedStreamName
	AND r2.MappingType = 'Revenue') as OrderNo
FROM ReferenceStreamMapping r1
LEFT OUTER JOIN v_SourceCCPTLThisNextyear v1
				ON v1.RevSourceName = r1.RevSourceName
				AND v1.RevStreamGroupName = r1.RevStreamGroupName
				--  Blank text allows selection of all
				AND (v1.RevStreamName = r1.RevStreamName OR r1.RevStreamName = '')
WHERE	r1.MappingType = 'Revenue'
		AND v1.Month BETWEEN @Month AND DATEADD(m,@MonthSpan - 1,@Month)
		AND v1.SalesGroupName IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@SalesGroupsInclude,','))
GROUP BY v1.SalesGroupName
	,r1.MappingStream 
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
END
---
GO
/****** Object:  StoredProcedure [dbo].[RevenueBreakdownNextYear]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[RevenueBreakdownNextYear] 
@RevenueStartMonth Date
,@SalesGroupName VARCHAR(256)
AS
BEGIN
SET NOCOUNT ON;
--
SELECT r1.MappingStream	
	,v1.Month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
	,SUM(v1.NetValueStnProfit) AS NetValueStnProfit
	,DATEDIFF(m,@RevenueStartMonth,v1.MONTH) + 1 AS MonthNo
	,(SELECT MIN(r2.OrderNo) FROM ReferenceStreamMapping r2 WHERE
	r2.MappingStream = r1.MappingStream 
	AND r2.MappedStreamName = r1.MappedStreamName
	AND r2.MappingType = 'Revenue') AS OrderNo
FROM ReferenceStreamMapping r1
LEFT OUTER JOIN v_SourceCCPTLNextYear v1
				ON v1.RevSourceName = r1.RevSourceName
				AND v1.RevStreamGroupName = r1.RevStreamGroupName
				--  Blank text allows selection of all
				AND (v1.RevStreamName = r1.RevStreamName OR r1.RevStreamName = '')
				AND v1.SalesGroupName IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@SalesGroupName,','))
WHERE r1.MappingType = 'Revenue'
GROUP BY r1.MappingStream 
	,v1.month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
END
GO
/****** Object:  StoredProcedure [dbo].[RevenueSummaryBreakdown]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






---------------------------------------------------------
CREATE PROCEDURE [dbo].[RevenueSummaryBreakdown] 
AS
BEGIN
SET NOCOUNT ON;
----------------------------------------------------------------------------------------------------------
DECLARE @YearStart DATETIME, @SalesGroupBreakdownPosition INT, @SalesGroupBreakdownName VARCHAR(30), @SalesGroups VARCHAR(500), @AdventureFlag CHAR(1), @MonthCounter INT
SET @YearStart = (SELECT MIN(r.Month) AS RevenueStartMonth FROM Revenue r)
--
IF OBJECT_ID('tempdb..#TempRevenueSummary','U') IS NOT NULL
				DROP TABLE #TempRevenueSummary
--
CREATE TABLE #TempRevenueSummary (
SalesGroupBreakdownPosition INT
,SalesGroupBreakdownName VARCHAR(30)
,SalesGroups VARCHAR(500)
,AdventureFlag CHAR(1)
,Month DATETIME
,MonthNo INT
,NetValueStnProfitLocal FLOAT
,TargetLocal FLOAT
,NetValueStnProfitLocalLastYear FLOAT
,NetValueBillableGlobal FLOAT
,TargetGlobal FLOAT
,NetValueBillableGlobalLastYear FLOAT
)

DECLARE RevenueSummary_Cursor CURSOR FOR   
SELECT SalesGroupBreakdownPosition, SalesGroupBreakdownName, SalesGroups, AdventureFlag FROM ReferenceSalesGroupBreakdownSFT
--
OPEN RevenueSummary_Cursor  
FETCH NEXT FROM RevenueSummary_Cursor   
INTO @SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @SalesGroups, @AdventureFlag
WHILE @@FETCH_STATUS = 0  
	BEGIN
	SET @MonthCounter = 0
	WHILE (@MonthCounter < 14)
		BEGIN
			INSERT INTO #TempRevenueSummary VALUES (@SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @SalesGroups, @AdventureFlag,DATEADD(M,@MonthCounter,@YearStart),@MonthCounter + 1,0,0,0,0,0,0)
			SET @MonthCounter = @MonthCounter + 1
		END
	FETCH NEXT FROM RevenueSummary_Cursor INTO @SalesGroupBreakdownPosition, @SalesGroupBreakdownName, @SalesGroups, @AdventureFlag
	END
-- Close curosr
CLOSE RevenueSummary_Cursor
DEALLOCATE RevenueSummary_Cursor
----------------------------------------------------------------------
SELECT	t.SalesGroupBreakdownPosition
		,t.SalesGroupBreakdownName
		,t.SalesGroups
		,t.AdventureFlag
		,t.Month
		,t.MonthNo
		,SUM(v1.NetValueStnProfitLocal) AS NetValueStnProfitLocal		 
		,SUM(v1.TargetLocal) AS TargetLocal
		,SUM(v1.NetValueStnProfitLocalLastYear) AS NetValueStnProfitLocalLastYear
		,SUM(v1.NetValueBillableGlobal) AS NetValueBillableGlobal
		,SUM(v1.TargetGlobal) AS TargetGlobal
		,SUM(v1.NetValueBillableLastYear) AS NetValueBillableLastYear
FROM #TempRevenueSummary t
JOIN v_RevenueSummaryBreakdown v1 ON	v1.SalesGroupName IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(t.SalesGroups,','))
										AND v1.Month = t.Month 
GROUP BY t.SalesGroupBreakdownPosition
		,t.SalesGroupBreakdownName
		,t.SalesGroups
		,t.AdventureFlag
		,t.Month
		,t.MonthNo
--
-- Clean up
DROP TABLE #TempRevenueSummary
-----------------------------------------------------------------------------
END
--
GO
/****** Object:  StoredProcedure [dbo].[RevenueTargetBreakdownCCP]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RevenueTargetBreakdownCCP] 
@RevenueStartMonth Date
AS
BEGIN
SET NOCOUNT ON;
----
WITH oa0 (SalesGroupName, MappingStream, Month, NetValueStnProfit, TeamTarget) AS
(
SELECT	v1.SalesGroupName 
	,r1.MappingStream	
	,v1.Month
	,SUM(v1.NetValueStnProfit) AS NetValueStnProfit
	,0 AS TeamTarget
FROM ReferenceStreamMapping r1
LEFT OUTER JOIN v_SourceCCPTL v1
				ON v1.RevSourceName = r1.RevSourceName
				AND v1.RevStreamGroupName = r1.RevStreamGroupName
				--  Blank text allows selection of all
				AND (v1.RevStreamName = r1.RevStreamName OR r1.RevStreamName = '')		
WHERE r1.MappingType = 'Revenue'
	
GROUP BY v1.SalesGroupName 
	,r1.MappingStream 
	,v1.month
UNION
SELECT	v1.SalesGroupName 
	,r1.MappingStream	
	,v1.Month
	,0
	,SUM(v1.TeamTarget)
FROM ReferenceStreamMapping r1
LEFT OUTER JOIN v_SourceMasterTarget v1
				ON v1.RevSourceName = r1.RevSourceName
				AND v1.RevStreamGroupName = r1.RevStreamGroupName
				--  Blank text allows selection of all
				AND (v1.RevStreamName = r1.RevStreamName OR r1.RevStreamName = '')	
WHERE r1.MappingType = 'Target'
GROUP BY v1.SalesGroupName 
	,r1.MappingStream 
	,v1.month
)
--
SELECT rsbs.SalesGroupBreakdownName
	,rsbs.SalesGroupBreakdownPosition
	,oa1.MappingStream	
	,oa1.Month
	,DATEDIFF(m,@RevenueStartMonth,oa1.MONTH) + 1 AS MonthNo
	,SUM(oa1.NetValueStnProfit) AS NetValueStnProfit
	,SUM(oa1.TeamTarget) AS TeamTarget
FROM ReferenceSalesGroupBreakdownSFT rsbs
OUTER APPLY
(SELECT * FROM oa0
WHERE oa0.SalesGroupName IN ((SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(rsbs.SalesGroups,',')))
) oa1
WHERE rsbs.AdventureFlag = 0
	-- Ignore House & Non Contracted Agency
	AND rsbs.SalesGroupBreakdownName NOT IN ('House','Non Contracted Agency')
GROUP BY  rsbs.SalesGroupBreakdownName
	,rsbs.SalesGroupBreakdownPosition
	,oa1.MappingStream	
	,oa1.Month
----
END
GO
/****** Object:  StoredProcedure [dbo].[selectnotcomputed]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[selectnotcomputed] 
@table VARCHAR(256)
AS
BEGIN
SET NOCOUNT ON;
--
SET QUOTED_IDENTIFIER ON
declare @sql nvarchar(max)
set @sql = 'select '
select @sql = @sql + '[' + name +'],' from sys.columns
where   object_id   = object_id(@table) and is_computed = 0
set @sql = left(@sql,len(@sql)-1) 
set @sql = @sql + @table
exec sp_executesql @sql
END

GO
/****** Object:  StoredProcedure [dbo].[TargetBreakdown]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[TargetBreakdown] 
@RevenueStartMonth Date
,@SalesGroupName VARCHAR(256)
AS
BEGIN
SET NOCOUNT ON;
--
SELECT r1.MappingStream	
	,v1.Month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
	,SUM(v1.TeamTarget) AS TeamTarget
	,DATEDIFF(m,@RevenueStartMonth,v1.MONTH) + 1 AS MonthNo
	,(SELECT MIN(r2.OrderNo) FROM ReferenceStreamMapping r2 WHERE
	r2.MappingStream = r1.MappingStream 
	AND r2.MappedStreamName = r1.MappedStreamName
	AND r2.MappingType = 'Target') AS OrderNo
FROM ReferenceStreamMapping r1
LEFT OUTER JOIN v_SourceMasterTarget v1
				ON v1.RevSourceName = r1.RevSourceName
				AND v1.RevStreamGroupName = r1.RevStreamGroupName
				--  Blank text allows selection of all
				AND (v1.RevStreamName = r1.RevStreamName OR r1.RevStreamName = '')
				AND v1.SalesGroupName IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@SalesGroupName,','))
WHERE r1.MappingType = 'Target'
GROUP BY r1.MappingStream 
	,v1.month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
END
GO
/****** Object:  StoredProcedure [dbo].[TargetBreakdownLastYear]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[TargetBreakdownLastYear] 
@RevenueStartMonth Date
,@SalesGroupName VARCHAR(256)
AS
BEGIN
SET NOCOUNT ON;
--
SELECT r1.MappingStream	
	,v1.Month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
	,SUM(v1.TeamTarget) AS TeamTarget
	,DATEDIFF(m,@RevenueStartMonth,v1.MONTH) + 1 AS MonthNo
	,(SELECT MIN(r2.OrderNo) FROM ReferenceStreamMapping r2 WHERE
	r2.MappingStream = r1.MappingStream 
	AND r2.MappedStreamName = r1.MappedStreamName
	AND r2.MappingType = 'Target') AS OrderNo
FROM ReferenceStreamMapping r1
LEFT OUTER JOIN v_SourceMasterTargetLastYear v1
				ON v1.RevSourceName = r1.RevSourceName
				AND v1.RevStreamGroupName = r1.RevStreamGroupName
				--  Blank text allows selection of all
				AND (v1.RevStreamName = r1.RevStreamName OR r1.RevStreamName = '')
				AND v1.SalesGroupName IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@SalesGroupName,','))
WHERE r1.MappingType = 'Target'
GROUP BY r1.MappingStream 
	,v1.month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
END
GO
/****** Object:  StoredProcedure [dbo].[TargetBreakdownMonth]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[TargetBreakdownMonth] 
@Month Date
,@MonthSpan INT
,@SalesGroupsInclude VARCHAR(500)
AS
BEGIN
SET NOCOUNT ON;
--
SELECT v1.SalesGroupName
	,r1.MappingStream	
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
	,SUM(v1.TeamTarget) AS TeamTarget
	,(SELECT MIN(r2.OrderNo) FROM ReferenceStreamMapping r2 WHERE
	r2.MappingStream = r1.MappingStream 
	AND r2.MappedStreamName = r1.MappedStreamName
	AND r2.MappingType = 'Target') AS OrderNo
FROM ReferenceStreamMapping r1
LEFT OUTER JOIN v_SourceMasterTargetThisNextYear v1
				ON v1.RevSourceName = r1.RevSourceName
				AND v1.RevStreamGroupName = r1.RevStreamGroupName
				--  Blank text allows selection of all
				AND (v1.RevStreamName = r1.RevStreamName OR r1.RevStreamName = '')
WHERE r1.MappingType = 'Target'
	AND v1.Month BETWEEN @Month AND DATEADD(m,@MonthSpan - 1,@Month)
	AND v1.SalesGroupName IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@SalesGroupsInclude,','))
GROUP BY v1.SalesGroupName
	,r1.MappingStream 
	,v1.month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
END
GO
/****** Object:  StoredProcedure [dbo].[TargetBreakdownNextYear]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








-- =============================================
-- Author:		Graham Cape
-- Create date: 08 May 2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[TargetBreakdownNextYear] 
@RevenueStartMonth Date
,@SalesGroupName VARCHAR(256)
AS
BEGIN
SET NOCOUNT ON;
--
SELECT r1.MappingStream	
	,v1.Month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
	,SUM(v1.TeamTarget) AS TeamTarget
	,DATEDIFF(m,@RevenueStartMonth,v1.MONTH) + 1 AS MonthNo
	,(SELECT MIN(r2.OrderNo) FROM ReferenceStreamMapping r2 WHERE
	r2.MappingStream = r1.MappingStream 
	AND r2.MappedStreamName = r1.MappedStreamName
	AND r2.MappingType = 'Target') AS OrderNo
FROM ReferenceStreamMapping r1
LEFT OUTER JOIN v_SourceMasterTargetNextYear v1
				ON v1.RevSourceName = r1.RevSourceName
				AND v1.RevStreamGroupName = r1.RevStreamGroupName
				--  Blank text allows selection of all
				AND (v1.RevStreamName = r1.RevStreamName OR r1.RevStreamName = '')
				AND v1.SalesGroupName IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(@SalesGroupName,','))
WHERE r1.MappingType = 'Target'
GROUP BY r1.MappingStream 
	,v1.month
	,r1.RevSourceName
	,r1.RevStreamGroupName
	,r1.MappedStreamName
END
GO
/****** Object:  StoredProcedure [dbo].[zzzInvoiceRunSelectionDetail]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[zzzInvoiceRunSelectionDetail] 
@InvoiceDate DATE
AS
BEGIN
SET NOCOUNT ON;
-----------------------------------------------------------------
SELECT	rih.INVOICEDATE AS InvoiceDate
		,rih.INVOICERUNID AS InvoiceRunID
        ,CASE when COALESCE(cwc.ACCOUNTSREF,'') = '' THEN ro.ACCOUNTCRN COLLATE Latin1_General_CI_AS
		ELSE cwc.ACCOUNTSREF END AS CCRN_CRN
        --,COALESCE(cwc.ACCOUNTSREF,'') AS CCRN
        --,ro.ACCOUNTCRN AS CRN
		,ras.STATIONGROUPID AS StationGroupid
		,ro.STATIONID AS StationID
		,ro.ORDERTYPEID AS OrderTypeID
		,COALESCE(roa.OATYPEID,0) AS ProductID
        ,ro.DATASOURCECAMPAIGN AS CampaignID
		--,rgsm.GPStationID AS GPStationID
		--,rncm.NominalCode
		,COALESCE(CONVERT(VARCHAR(10),rgsm.GPStationID),'??')
		+ COALESCE(rncm.NominalCode,'??') AS NominalMappingCode
		-- Cost Breakdowns
		,ril.LINEVALUE AS LineValue
		--,ril.COMMISSIONRATE AS CommissionRate
		,CAST(ROUND(((ril.LINEVALUE * ril.COMMISSIONRATE)/100),2) AS DECIMAL(10,2)) AS Commission
		,ril.LINEVALUE - CAST(ROUND(((ril.LINEVALUE * ril.COMMISSIONRATE)/100),2) AS DECIMAL(10,2)) AS NetValue
FROM	CCTRAFFICLIVE.dbo.RAINVOICEHEADERS rih
JOIN	CCTRAFFICLIVE.dbo.RAORDERS ro ON ro.ORDERID = rih.ORDERID
JOIN	CCTRAFFICLIVE.dbo.RAINVOICELINES ril WITH (NOLOCK) ON ril.INVOICEHEADERID = rih.INVOICEHEADERID
LEFT OUTER JOIN CCTRAFFICLIVE.dbo.RASTATIONS ras ON ras.STATIONID = ro.STATIONID
LEFT OUTER JOIN CCPLANITLIVE.dbo.[Campaigns with CCRN] cwc ON cwc.CAMPAIGNID = ro.DATASOURCECAMPAIGN
LEFT OUTER JOIN CCTRAFFICLIVE.dbo.RAOFFAIRACTIVITIES roa ON roa.INVOICELINEID = ril.INVOICELINEID
LEFT OUTER JOIN Greens.dbo.ReferenceGPStationMapping rgsm ON rgsm.StationGroupID = ras.STATIONGROUPID
LEFT OUTER JOIN Greens.dbo.ReferenceNominalCodeMapping rncm ON rncm.OrderTypeID_OATypeID = 
			CONVERT(VARCHAR(10),ro.ORDERTYPEID) + '_' + CONVERT(VARCHAR(10),COALESCE(roa.OATYPEID,'0'))
WHERE	rih.INVOICEDATE = @InvoiceDate
        -- Ignore national campaigns
		AND COALESCE(ro.SALESHOUSEID,0) NOT IN (11,14,15)
ORDER BY INVOICERUNID, CCRN_CRN, StationID, ProductID, CampaignID
--
END
--
GO
/****** Object:  StoredProcedure [dbo].[zzzInvoiceRunSelectionSummary]    Script Date: 18/09/2024 16:19:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[zzzInvoiceRunSelectionSummary] 
@InvoiceDate DATE
AS
BEGIN
SET NOCOUNT ON;
----------------------------------------------
WITH run1 (InvoiceRunID,InvoiceDate,CCRN_CRN,CCRN,CRN,CampaignID,NetValue) AS 
(
SELECT	rih.INVOICEDATE AS InvoiceDate
		,rih.INVOICERUNID AS InvoiceRunID
        ,CASE when COALESCE(cwc.ACCOUNTSREF,'') = '' THEN ro.ACCOUNTCRN COLLATE Latin1_General_CI_AS
		ELSE cwc.ACCOUNTSREF END AS CCRN_CRN
        ,COALESCE(cwc.ACCOUNTSREF,'') AS CCRN
        ,ro.ACCOUNTCRN AS CRN
        ,ro.DATASOURCECAMPAIGN AS CampaignID
		,(rih.LINEVALUE - rih.COMMISSIONPAYABLE) AS NetValue
FROM CCTRAFFICLIVE.dbo.RAINVOICEHEADERS rih
JOIN CCTRAFFICLIVE.dbo.RAORDERS ro ON ro.ORDERID = rih.ORDERID
LEFT OUTER JOIN CCPLANITLIVE.dbo.[Campaigns with CCRN] cwc ON cwc.CAMPAIGNID = ro.DATASOURCECAMPAIGN
WHERE	rih.INVOICEDATE = @InvoiceDate
		--rih.INVOICEDATE = '30 SEP 2018'
        -- Ignore national campaigns
		AND COALESCE(ro.SALESHOUSEID,0) NOT IN (11,14,15)
		
)
--------------------------------------------------------------
SELECT	r1.InvoiceDate
		,r1.InvoiceRunID
        ,r1.CCRN_CRN
		,r1.CCRN
        ,r1.CRN
		,	(SELECT DISTINCT r2.CampaignID FROM run1 r2 WHERE r2.CCRN_CRN = r1.CCRN_CRN AND r2.InvoiceRunID = r1.InvoiceRunID 
			ORDER BY r2.CampaignID OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY) AS CampaignID1
		,	COALESCE((SELECT DISTINCT r2.CampaignID FROM run1 r2 WHERE r2.CCRN_CRN = r1.CCRN_CRN AND r2.InvoiceRunID = r1.InvoiceRunID 
			ORDER BY r2.CampaignID OFFSET 1 ROWS FETCH FIRST 1 ROWS ONLY),0) AS CampaignID2
		,	COALESCE((SELECT DISTINCT r2.CampaignID FROM run1 r2 WHERE r2.CCRN_CRN = r1.CCRN_CRN AND r2.InvoiceRunID = r1.InvoiceRunID 
			ORDER BY r2.CampaignID OFFSET 2 ROWS FETCH FIRST 1 ROWS ONLY),0) AS CampaignID3
		,SUM(NetValue) AS NetValue
FROM run1 r1
GROUP BY	r1.InvoiceDate
			,r1.InvoiceRunID
			,r1.CCRN_CRN
			,r1.CCRN
			,r1.CRN
ORDER BY r1.InvoiceRunID, r1.CCRN_CRN
-----------------------
END
GO
