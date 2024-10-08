USE [master]
GO
/****** Object:  Database [Greens]    Script Date: 18/09/2024 16:05:06 ******/
CREATE DATABASE [Greens]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Greens', FILENAME = N'/sqldata/db2/data/Greens.mdf' , SIZE = 3743744KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Greens_log', FILENAME = N'/sqldata/db2/logs/Greens_log.ldf' , SIZE = 26681344KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [Greens] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Greens].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Greens] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Greens] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Greens] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Greens] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Greens] SET ARITHABORT OFF 
GO
ALTER DATABASE [Greens] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Greens] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Greens] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Greens] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Greens] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Greens] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Greens] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Greens] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Greens] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Greens] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Greens] SET AUTO_UPDATE_STATISTICS_ASYNC ON 
GO
ALTER DATABASE [Greens] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Greens] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Greens] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Greens] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Greens] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Greens] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Greens] SET RECOVERY FULL 
GO
ALTER DATABASE [Greens] SET  MULTI_USER 
GO
ALTER DATABASE [Greens] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Greens] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Greens] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Greens] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [Greens] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [Greens] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'Greens', N'ON'
GO
ALTER DATABASE [Greens] SET QUERY_STORE = OFF
GO
USE [Greens]
GO
/****** Object:  User [graf]    Script Date: 18/09/2024 16:05:07 ******/
CREATE USER [graf] FOR LOGIN [graf] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_datareader] ADD MEMBER [graf]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_RevenueSummaryWeekSplit]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE FUNCTION [dbo].[fn_RevenueSummaryWeekSplit](@Date DATE)
RETURNS INT 
AS
BEGIN
----------------------------------------------------------------------------------------------------------------
DECLARE @MonthStart DATE, @MonthStartDay INT, @FirstMondayDate DATE, @Week2Start DATE, @Week3Start DATE, @Week4Start DATE, @WeekNo INT
SET @MonthStart = dateadd(M,datediff(M,'01/01/1900',@Date),'01/01/1900')
-- Get day 1 = Sunday 7 = Saturday
SET @MonthStartDay = DATEPART(dw,@MonthStart)
-- Get first Monday date
SET @FirstMondayDate = DATEADD(D,	CASE	WHEN @MonthStartDay = 2 THEN 0
											WHEN @MonthStartDay = 1 THEN 1
											ELSE 9 - @MonthStartDay
									END
									,@monthStart)
-- Set MonthStart to Working Day
SET @MonthStart = (CASE WHEN @MonthStartDay = 1 THEN DATEADD(D,1,@MonthStart)
						WHEN @MonthStartDay = 7 THEN DATEADD(D,2,@MonthStart)
						ELSE @MonthStart
					END)
-- Calculate Week Splits
SET @Week2Start = (CASE WHEN @FirstMondayDate = @MonthStart THEN DATEADD(D,7,@MonthStart)
						ELSE @FirstMondayDate
					END)
SET @Week3Start = DATEADD(D,7,@Week2Start)
SET @Week4Start = DATEADD(D,7,@Week3Start)
-- Get week number
SET @WeekNo =	(CASE	WHEN @Date < @Week2Start THEN 1
						WHEN @date < @Week3Start THEN 2
						WHEN @date < @Week4Start THEN 3
						ELSE 4
				END)
RETURN @WeekNo
--
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_Split]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_Split](@sText varchar(8000), @sDelim varchar(20) = ' ')
RETURNS @retArray TABLE (idx smallint Primary Key, value varchar(8000))
AS
BEGIN
DECLARE @idx smallint,
       @value varchar(8000),
       @bcontinue bit,
       @iStrike smallint,
       @iDelimlength tinyint

IF @sDelim = 'Space'
       BEGIN
       SET @sDelim = ' '
       END

SET @idx = 0
SET @sText = LTrim(RTrim(@sText))
SET @iDelimlength = DATALENGTH(@sDelim)
SET @bcontinue = 1

IF NOT ((@iDelimlength = 0) or (@sDelim = 'Empty'))
       BEGIN
       WHILE @bcontinue = 1
              BEGIN

--If you can find the delimiter in the text, retrieve the first element and
--insert it with its index into the return table.

              IF CHARINDEX(@sDelim, @sText)>0
                     BEGIN
                     SET @value = SUBSTRING(@sText,1, CHARINDEX(@sDelim,@sText)-1)
                           BEGIN
                           INSERT @retArray (idx, value)
                           VALUES (@idx, @value)
                           END
                     
--Trim the element and its delimiter from the front of the string.
                     --Increment the index and loop.
SET @iStrike = DATALENGTH(@value) + @iDelimlength
                     SET @idx = @idx + 1
                     SET @sText = LTrim(Right(@sText,DATALENGTH(@sText) - @iStrike))
              
                     END
              ELSE
                     BEGIN
--If you can’t find the delimiter in the text, @sText is the last value in
--@retArray.
SET @value = @sText
                           BEGIN
                           INSERT @retArray (idx, value)
                           VALUES (@idx, @value)
                           END
                     --Exit the WHILE loop.
SET @bcontinue = 0
                     END
              END
       END
ELSE
       BEGIN
       WHILE @bcontinue=1
              BEGIN
              --If the delimiter is an empty string, check for remaining text
              --instead of a delimiter. Insert the first character into the
              --retArray table. Trim the character from the front of the string.
--Increment the index and loop.
              IF DATALENGTH(@sText)>1
                     BEGIN
                     SET @value = SUBSTRING(@sText,1,1)
                           BEGIN
                           INSERT @retArray (idx, value)
                           VALUES (@idx, @value)
                           END
                     SET @idx = @idx+1
                     SET @sText = SUBSTRING(@sText,2,DATALENGTH(@sText)-1)
                     
                     END
              ELSE
                     BEGIN
                     --One character remains.
                     --Insert the character, and exit the WHILE loop.
                     INSERT @retArray (idx, value)
                     VALUES (@idx, @sText)
                     SET @bcontinue = 0   
                     END
       END

END

RETURN
END


GO
/****** Object:  Table [dbo].[ReferenceSourceFilters]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReferenceSourceFilters](
	[SourceType] [varchar](256) NULL,
	[SourceDataName] [varchar](256) NULL,
	[SourceDataValueIncluded] [varchar](256) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RevenuePastYears]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RevenuePastYears](
	[Category] [varchar](11) NOT NULL,
	[ORDERID] [int] NOT NULL,
	[IMPORTED] [datetime] NULL,
	[ORDERTITLE] [varchar](128) NULL,
	[DATASOURCECAMPAIGN] [varchar](20) NULL,
	[STATIONGROUPNAME] [varchar](256) NULL,
	[Station] [varchar](256) NULL,
	[Month] [datetime] NULL,
	[CAMPAIGN TYPE] [varchar](64) NULL,
	[Cost Type] [varchar](64) NULL,
	[SALESEXECNAME] [varchar](128) NULL,
	[SALESGROUPNAME] [varchar](256) NULL,
	[CLIENTNAME] [varchar](128) NULL,
	[CLIENTID] [int] NULL,
	[AGENCYNAME] [varchar](128) NULL,
	[AgencyAndClient] [varchar](259) NULL,
	[AGENCYCRN] [varchar](16) NULL,
	[CLIENTCRN] [varchar](16) NULL,
	[EXTERNALREF] [varchar](32) NULL,
	[SPOTTYPEDESCRIPTION] [varchar](64) NULL,
	[Spots] [int] NULL,
	[Gross Value] [float] NULL,
	[Net Value] [float] NULL,
	[Agency Commission] [float] NULL,
	[Net Value Billable] [float] NULL,
	[Vat] [float] NULL,
	[Total] [float] NULL,
	[Budget] [float] NULL,
	[ExecTarget] [float] NOT NULL,
	[TeamTarget] [float] NOT NULL,
	[Net Value Stn Profit] [float] NULL,
	[JCN] [varchar](16) NULL,
	[ORDERVERSIONNO] [int] NULL,
	[CREATEDDATETIME] [datetime] NULL,
	[RevMap] [varchar](128) NULL,
	[RevStreamName] [varchar](50) NULL,
	[RevStreamGroupName] [varchar](50) NULL,
	[RevSourceName] [varchar](50) NULL,
	[GlobalTeam] [varchar](256) NULL,
	[BARTERPERCENT] [float] NULL,
	[BarterDiff] [float] NULL,
	[SourceCompanyName] [varchar](50) NULL,
	[Assisted] [varchar](11) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Revenue]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Revenue](
	[Category] [varchar](11) NOT NULL,
	[ORDERID] [int] NOT NULL,
	[IMPORTED] [datetime] NULL,
	[ORDERTITLE] [varchar](128) NULL,
	[DATASOURCECAMPAIGN] [varchar](20) NULL,
	[STATIONGROUPNAME] [varchar](256) NULL,
	[Station] [varchar](256) NULL,
	[Month] [datetime] NULL,
	[CAMPAIGN TYPE] [varchar](64) NULL,
	[Cost Type] [varchar](64) NULL,
	[SALESEXECNAME] [varchar](128) NULL,
	[SALESGROUPNAME] [varchar](256) NULL,
	[CLIENTNAME] [varchar](128) NULL,
	[CLIENTID] [int] NULL,
	[AGENCYNAME] [varchar](128) NULL,
	[AgencyAndClient] [varchar](259) NULL,
	[AGENCYCRN] [varchar](16) NULL,
	[CLIENTCRN] [varchar](16) NULL,
	[EXTERNALREF] [varchar](32) NULL,
	[SPOTTYPEDESCRIPTION] [varchar](64) NULL,
	[Spots] [int] NULL,
	[Gross Value] [float] NULL,
	[Net Value] [float] NULL,
	[Agency Commission] [float] NULL,
	[Net Value Billable] [float] NULL,
	[Vat] [float] NULL,
	[Total] [float] NULL,
	[Budget] [float] NULL,
	[ExecTarget] [float] NOT NULL,
	[TeamTarget] [float] NOT NULL,
	[Net Value Stn Profit] [float] NULL,
	[JCN] [varchar](16) NULL,
	[ORDERVERSIONNO] [int] NULL,
	[CREATEDDATETIME] [datetime] NULL,
	[RevMap] [varchar](128) NULL,
	[RevStreamName] [varchar](50) NULL,
	[RevStreamGroupName] [varchar](50) NULL,
	[RevSourceName] [varchar](50) NULL,
	[GlobalTeam] [varchar](256) NULL,
	[BARTERPERCENT] [float] NULL,
	[BarterDiff] [float] NULL,
	[SourceCompanyName] [varchar](50) NULL,
	[Assisted] [varchar](11) NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[v_RevenueLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









--
CREATE VIEW [dbo].[v_RevenueLastYear] AS
----
SELECT * FROM RevenuePastYears r WITH (NOLOCK) WHERE
r.Month BETWEEN DATEADD(M,-12,(SELECT MIN(month) FROM Revenue)) AND DATEADD(M,-1,(SELECT MIN(month) FROM Revenue))
--
GO
/****** Object:  Table [dbo].[ReferenceStreamMapping]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReferenceStreamMapping](
	[MappingStream] [varchar](50) NULL,
	[MappingType] [varchar](50) NULL,
	[RevSourceName] [varchar](50) NULL,
	[RevStreamGroupName] [varchar](50) NULL,
	[RevStreamName] [varchar](50) NULL,
	[MappedStreamName] [varchar](50) NULL,
	[OrderNo] [int] NULL,
	[GAWRevStreamName] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutiveLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[v_SourceGlobalAssistedWinsExecutiveLastYear] AS
SELECT	r.SALESGROUPNAME as SalesGroupName
	,rsm.RevSourceName
	,r.SALESEXECNAME AS SalesExecName
	,r.Month
	,SUM(r.[Net Value Billable]) AS NetValueBillable
	,SUM(r.ExecTarget) AS ExecTarget
FROM v_RevenueLastYear r
LEFT OUTER JOIN ReferenceStreamMapping rsm WITH (NOLOCK) ON rsm.GAWRevStreamName = r.RevStreamName
WHERE r.Assisted = 'GAW'
GROUP BY r.SALESGROUPNAME
	,rsm.RevSourceName
	,r.SALESEXECNAME
	,r.Month


GO
/****** Object:  View [dbo].[v_SourceSalesExecutiveLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[v_SourceSalesExecutiveLastYear] AS
----
SELECT	vall.SalesGroupName
		,vall.RevSourceName
		,vall.SalesExecName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
		,SUM(vall.ExecTarget) AS ExecTarget
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.SALESEXECNAME AS SalesExecName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
		,r.ExecTarget
FROM v_RevenueLastYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevSourceName
	,v.SalesExecName
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
	,v.ExecTarget
FROM v_SourceGlobalAssistedWinsExecutiveLastYear v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.SalesExecName, vall.Month
--

GO
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutiveClientLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE VIEW [dbo].[v_SourceGlobalAssistedWinsExecutiveClientLastYear] AS
SELECT	r.SALESEXECNAME AS SalesExecName
		,r.CLIENTNAME AS ClientName
		,r.Month
		,SUM(r.[Net Value Billable]) AS NetValueBillable
		,SUM(r.ExecTarget) AS ExecTarget
FROM v_RevenueLastYear r
WHERE r.Assisted = 'GAW'
GROUP BY r.SALESEXECNAME, r.CLIENTNAME, r.Month

GO
/****** Object:  View [dbo].[v_SalesExecutiveEmail]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SalesExecutiveEmail]
AS
SELECT DISTINCT SALESEXECNAME, LOWER(EMAILADDRESS) AS EMAILADDRESS
FROM     CCPLANITLIVE.dbo.SALESEXEC AS s WITH (NOLOCK)
WHERE  (ACCESS1 <> 'Z') AND (EMAILADDRESS IS NOT NULL) AND (EMAILADDRESS <> '') AND EXISTS
                      (SELECT SALESEXECNAME
                       FROM      dbo.Revenue AS r
                       WHERE   (SALESEXECNAME COLLATE Latin1_General_CI_AS = s.SALESEXECNAME) AND (Category = 'Revenue')) OR
                  EXISTS
                      (SELECT SALESEXECNAME
                       FROM      dbo.RevenuePastYears AS rp
                       WHERE   (SALESEXECNAME COLLATE Latin1_General_CI_AS = s.SALESEXECNAME) AND (Category = 'Revenue'))
GO
/****** Object:  View [dbo].[VET_RevenueExecEmail]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_RevenueExecEmail]
AS
SELECT        dbo.Revenue.Category, dbo.Revenue.ORDERID, dbo.Revenue.IMPORTED, dbo.Revenue.ORDERTITLE, dbo.Revenue.DATASOURCECAMPAIGN, dbo.Revenue.STATIONGROUPNAME, dbo.Revenue.Station, dbo.Revenue.Month, 
                         dbo.Revenue.[CAMPAIGN TYPE], dbo.Revenue.[Cost Type], dbo.Revenue.SALESEXECNAME, dbo.Revenue.SALESGROUPNAME, dbo.Revenue.CLIENTNAME, dbo.Revenue.CLIENTID, dbo.Revenue.AGENCYNAME, 
                         dbo.Revenue.AgencyAndClient, dbo.Revenue.AGENCYCRN, dbo.Revenue.CLIENTCRN, dbo.Revenue.EXTERNALREF, dbo.Revenue.SPOTTYPEDESCRIPTION, dbo.Revenue.Spots, dbo.Revenue.[Gross Value], 
                         dbo.Revenue.[Net Value], dbo.Revenue.[Agency Commission], dbo.Revenue.[Net Value Billable], dbo.Revenue.Vat, dbo.Revenue.Total, dbo.Revenue.Budget, dbo.Revenue.ExecTarget, dbo.Revenue.TeamTarget, 
                         dbo.Revenue.[Net Value Stn Profit], dbo.Revenue.JCN, dbo.Revenue.ORDERVERSIONNO, dbo.Revenue.CREATEDDATETIME, dbo.Revenue.RevMap, dbo.Revenue.RevStreamName, dbo.Revenue.RevStreamGroupName, 
                         dbo.Revenue.RevSourceName, dbo.Revenue.GlobalTeam, dbo.Revenue.BARTERPERCENT, dbo.Revenue.BarterDiff, dbo.Revenue.SourceCompanyName, dbo.Revenue.Assisted, 
                         dbo.v_SalesExecutiveEmail.EMAILADDRESS
FROM            dbo.Revenue INNER JOIN
                         dbo.v_SalesExecutiveEmail ON dbo.Revenue.SALESEXECNAME COLLATE Latin1_General_CI_AS = dbo.v_SalesExecutiveEmail.SALESEXECNAME
GO
/****** Object:  View [dbo].[VET_RevenuePastYearsExecEmail]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_RevenuePastYearsExecEmail]
AS
SELECT        dbo.RevenuePastYears.Category, dbo.RevenuePastYears.ORDERID, dbo.RevenuePastYears.IMPORTED, dbo.RevenuePastYears.ORDERTITLE, dbo.RevenuePastYears.DATASOURCECAMPAIGN, 
                         dbo.RevenuePastYears.STATIONGROUPNAME, dbo.RevenuePastYears.Station, dbo.RevenuePastYears.Month, dbo.RevenuePastYears.[CAMPAIGN TYPE], dbo.RevenuePastYears.[Cost Type], 
                         dbo.RevenuePastYears.SALESEXECNAME, dbo.RevenuePastYears.SALESGROUPNAME, dbo.RevenuePastYears.CLIENTNAME, dbo.RevenuePastYears.CLIENTID, dbo.RevenuePastYears.AGENCYNAME, 
                         dbo.RevenuePastYears.AgencyAndClient, dbo.RevenuePastYears.AGENCYCRN, dbo.RevenuePastYears.CLIENTCRN, dbo.RevenuePastYears.EXTERNALREF, dbo.RevenuePastYears.SPOTTYPEDESCRIPTION, 
                         dbo.RevenuePastYears.Spots, dbo.RevenuePastYears.[Gross Value], dbo.RevenuePastYears.[Net Value], dbo.RevenuePastYears.[Agency Commission], dbo.RevenuePastYears.[Net Value Billable], dbo.RevenuePastYears.Vat, 
                         dbo.RevenuePastYears.Total, dbo.RevenuePastYears.Budget, dbo.RevenuePastYears.ExecTarget, dbo.RevenuePastYears.TeamTarget, dbo.RevenuePastYears.[Net Value Stn Profit], dbo.RevenuePastYears.JCN, 
                         dbo.RevenuePastYears.ORDERVERSIONNO, dbo.RevenuePastYears.CREATEDDATETIME, dbo.RevenuePastYears.RevMap, dbo.RevenuePastYears.RevStreamName, dbo.RevenuePastYears.RevStreamGroupName, 
                         dbo.RevenuePastYears.RevSourceName, dbo.RevenuePastYears.GlobalTeam, dbo.RevenuePastYears.BARTERPERCENT, dbo.RevenuePastYears.BarterDiff, dbo.RevenuePastYears.SourceCompanyName, 
                         dbo.RevenuePastYears.Assisted, dbo.v_SalesExecutiveEmail.EMAILADDRESS
FROM            dbo.RevenuePastYears INNER JOIN
                         dbo.v_SalesExecutiveEmail ON dbo.RevenuePastYears.SALESEXECNAME = dbo.v_SalesExecutiveEmail.SALESEXECNAME
GO
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutiveClient]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[v_SourceGlobalAssistedWinsExecutiveClient] AS
SELECT	r.SALESEXECNAME AS SalesExecName
		,r.CLIENTNAME AS ClientName
		,r.Month
		,SUM(r.[Net Value Billable]) AS NetValueBillable
		,SUM(r.ExecTarget) AS ExecTarget
FROM Revenue r
WHERE r.Assisted = 'GAW'
GROUP BY r.SALESEXECNAME, r.CLIENTNAME, r.Month

GO
/****** Object:  View [dbo].[v_SourceExecutiveClient]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[v_SourceExecutiveClient] AS
----
SELECT	vall.SalesExecName
		,vall.ClientName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
		,SUM(vall.ExecTarget) AS ExecTarget
FROM
(
SELECT	r.SALESEXECNAME AS SalesExecName
		,r.CLIENTNAME AS ClientName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
		,r.ExecTarget
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesExecName
	,v.CLIENTNAME
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
	,v.ExecTarget
FROM v_SourceGlobalAssistedWinsExecutiveClient v
) vall
GROUP BY vall.SalesExecName, vall.ClientName, vall.Month
--

GO
/****** Object:  View [dbo].[v_SourceExecutiveClientLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[v_SourceExecutiveClientLastYear] AS
----
SELECT	vall.SalesExecName
		,vall.ClientName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
		,SUM(vall.ExecTarget) AS ExecTarget
FROM
(
SELECT	r.SALESEXECNAME AS SalesExecName
		,r.CLIENTNAME AS ClientName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
		,r.ExecTarget
FROM v_RevenueLastYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesExecName
	,v.CLIENTNAME
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
	,v.ExecTarget
FROM v_SourceGlobalAssistedWinsExecutiveClientLastYear v
) vall
GROUP BY vall.SalesExecName, vall.ClientName, vall.Month
--

GO
/****** Object:  View [dbo].[v_SourceGlobalAssistedWins]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceGlobalAssistedWins] AS
SELECT	r.SALESGROUPNAME as SalesGroupName 
	,rsm.RevSourceName
	,rsm.RevStreamGroupName
	,rsm.RevStreamName
	,r.Month
	,SUM(r.[Net Value Billable]) AS NetValueBillable
	,SUM(r.TeamTarget) AS TeamTarget
FROM Revenue r
LEFT OUTER JOIN ReferenceStreamMapping rsm WITH (NOLOCK) ON rsm.GAWRevStreamName = r.RevStreamName
WHERE r.Assisted = 'GAW'
GROUP BY r.SALESGROUPNAME
	,rsm.RevSourceName
	,rsm.RevStreamGroupName
	,rsm.RevStreamName
	,r.Month


GO
/****** Object:  View [dbo].[v_SourceNCARevenueTarget]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










--
CREATE VIEW [dbo].[v_SourceNCARevenueTarget] AS
----
SELECT vall.SalesGroupName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.AssistedFlag
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
		,SUM(vall.TeamTarget) AS TeamTarget
FROM
(
SELECT	r.SalesGroupName
		,r.RevStreamGroupName
		,r.RevStreamName
		,(CASE WHEN r.Assisted = 'CAW' THEN 'Y' ELSE 'N' END) AS AssistedFlag
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
		,r.TeamTarget

FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName = 'Agency'
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevStreamGroupName
	,v.RevStreamName
	,'N'
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
	,v.TeamTarget
FROM v_SourceGlobalAssistedWins v
WHERE v.RevStreamGroupName = 'Agency'
) vall
GROUP BY	vall.SalesGroupName, vall.RevStreamGroupName
			,vall.RevStreamName, vall.AssistedFlag, vall.Month
--
GO
/****** Object:  View [dbo].[v_RevenueLastYearPlus1]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










--
CREATE VIEW [dbo].[v_RevenueLastYearPlus1] AS
----
SELECT * FROM RevenuePastYears r WITH (NOLOCK) WHERE
r.Month BETWEEN DATEADD(M,-24,(SELECT MIN(month) FROM Revenue)) AND DATEADD(M,-13,(SELECT MIN(month) FROM Revenue))
--
GO
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutiveClientLastYearPlus1]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE VIEW [dbo].[v_SourceGlobalAssistedWinsExecutiveClientLastYearPlus1] AS
SELECT	r.SALESEXECNAME AS SalesExecName
		,r.CLIENTNAME AS ClientName
		,r.Month
		,SUM(r.[Net Value Billable]) AS NetValueBillable
		,SUM(r.ExecTarget) AS ExecTarget
FROM v_RevenueLastYearPlus1 r
WHERE r.Assisted = 'GAW'
GROUP BY r.SALESEXECNAME, r.CLIENTNAME, r.Month

GO
/****** Object:  View [dbo].[v_SourceExecutiveClientLastYearPlus1]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[v_SourceExecutiveClientLastYearPlus1] AS
----
SELECT	vall.SalesExecName
		,vall.ClientName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
		,SUM(vall.ExecTarget) AS ExecTarget
FROM
(
SELECT	r.SALESEXECNAME AS SalesExecName
		,r.CLIENTNAME AS ClientName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
		,r.ExecTarget
FROM v_RevenueLastYearPlus1 r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesExecName
	,v.CLIENTNAME
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
	,v.ExecTarget
FROM v_SourceGlobalAssistedWinsExecutiveClientLastYearPlus1 v
) vall
GROUP BY vall.SalesExecName, vall.ClientName, vall.Month
--

GO
/****** Object:  View [dbo].[v_SourceExecutiveGlobalAssistedWins]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[v_SourceExecutiveGlobalAssistedWins] AS
SELECT	r.SALESEXECNAME as SalesExecName 
	,rsm.RevSourceName
	,rsm.RevStreamGroupName
	,rsm.RevStreamName
	,r.Month
	,SUM(r.[Net Value Billable]) AS NetValueBillable
	,SUM(r.ExecTarget) AS ExecTarget
FROM Revenue r
LEFT OUTER JOIN ReferenceStreamMapping rsm WITH (NOLOCK) ON rsm.GAWRevStreamName = r.RevStreamName
WHERE r.Assisted = 'GAW'
GROUP BY r.SALESEXECNAME
	,rsm.RevSourceName
	,rsm.RevStreamGroupName
	,rsm.RevStreamName
	,r.Month


GO
/****** Object:  View [dbo].[v_SourceExecutiveMasterTarget]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












--
CREATE VIEW [dbo].[v_SourceExecutiveMasterTarget] AS
----
SELECT	vall.SalesExecName
		,vall.RevSourceName
		,vall.Month
		,SUM(vall.ExecTarget) AS ExecTarget
FROM
(
SELECT	r.SALESEXECNAME AS SalesExecName
		,r.RevSourceName
		,r.Month
		,r.ExecTarget
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
		-- Special to ignore NCA Assisted Wins and prevent double counting
		AND r.RevStreamName <> 'NCA Assisted Win'
UNION ALL
SELECT	v.SalesExecName
	,v.RevSourceName
	,v.Month
	,v.ExecTarget
FROM v_SourceExecutiveGlobalAssistedWins v
) vall
GROUP BY vall.SalesExecName, vall.RevSourceName, vall.Month
--
GO
/****** Object:  View [dbo].[VET_CurrentExecs]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--
CREATE VIEW [dbo].[VET_CurrentExecs] AS
----
SELECT	distinct SalesExecName
FROM
[dbo].[v_SourceExecutiveMasterTarget]
WHERE [Month] >= (SELECT DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE())-1, 1))
and exectarget > 0
--
GO
/****** Object:  Table [dbo].[RevenueNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RevenueNextYear](
	[Category] [varchar](11) NOT NULL,
	[ORDERID] [int] NOT NULL,
	[IMPORTED] [datetime] NULL,
	[ORDERTITLE] [varchar](128) NULL,
	[DATASOURCECAMPAIGN] [varchar](20) NULL,
	[STATIONGROUPNAME] [varchar](256) NULL,
	[Station] [varchar](256) NULL,
	[Month] [datetime] NULL,
	[CAMPAIGN TYPE] [varchar](64) NULL,
	[Cost Type] [varchar](64) NULL,
	[SALESEXECNAME] [varchar](128) NULL,
	[SALESGROUPNAME] [varchar](256) NULL,
	[CLIENTNAME] [varchar](128) NULL,
	[CLIENTID] [int] NULL,
	[AGENCYNAME] [varchar](128) NULL,
	[AgencyAndClient] [varchar](259) NULL,
	[AGENCYCRN] [varchar](16) NULL,
	[CLIENTCRN] [varchar](16) NULL,
	[EXTERNALREF] [varchar](32) NULL,
	[SPOTTYPEDESCRIPTION] [varchar](64) NULL,
	[Spots] [int] NULL,
	[Gross Value] [float] NULL,
	[Net Value] [float] NULL,
	[Agency Commission] [float] NULL,
	[Net Value Billable] [float] NULL,
	[Vat] [float] NULL,
	[Total] [float] NULL,
	[Budget] [float] NULL,
	[ExecTarget] [float] NOT NULL,
	[TeamTarget] [float] NOT NULL,
	[Net Value Stn Profit] [float] NULL,
	[JCN] [varchar](16) NULL,
	[ORDERVERSIONNO] [int] NULL,
	[CREATEDDATETIME] [datetime] NULL,
	[RevMap] [varchar](128) NULL,
	[RevStreamName] [varchar](50) NULL,
	[RevStreamGroupName] [varchar](50) NULL,
	[RevSourceName] [varchar](50) NULL,
	[GlobalTeam] [varchar](256) NULL,
	[BARTERPERCENT] [float] NULL,
	[BarterDiff] [float] NULL,
	[SourceCompanyName] [varchar](50) NULL,
	[Assisted] [varchar](11) NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[VET_AgencyCCRN]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_AgencyCCRN]
AS
SELECT        AGENCYNAME, AGENCYCRN, ACCOUNTSREF AS CCRN
FROM            CCTRAFFICLIVE.dbo.RAAGENCIES
WHERE        (AGENCYCRN IS NOT NULL) AND (ACCOUNTDISABLED <> 1)
GO
/****** Object:  View [dbo].[VET_ClientCCRN]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_ClientCCRN]
AS
SELECT        CLIENTNAME, CLIENTCRN, CCRN
FROM            CCTRAFFICLIVE.dbo.VET_ClientCCRN
GO
/****** Object:  View [dbo].[VET_3MthRevenue]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_3MthRevenue]
AS
(SELECT        [Category], [ORDERID], [IMPORTED], [ORDERTITLE] COLLATE database_default AS [ORDERTITLE], [DATASOURCECAMPAIGN] COLLATE database_default AS [DATASOURCECAMPAIGN], 
                          [STATIONGROUPNAME] COLLATE database_default AS [STATIONGROUPNAME], [Station] COLLATE database_default AS [STATION], [Month], [CAMPAIGN TYPE] COLLATE database_default AS [CAMPAIGN TYPE], 
                          [Cost Type] COLLATE database_default AS [Cost Type], [Greens].[dbo].[Revenue].[SALESEXECNAME] COLLATE database_default AS [SALESEXECNAME], 
                          [SALESGROUPNAME] COLLATE database_default AS [SALESGROUPNAME], dbo.revenue.[CLIENTNAME] COLLATE database_default AS [CLIENTNAME], [CLIENTID], dbo.revenue.[AGENCYNAME] COLLATE database_default AS [AGENCYNAME], 
                          [AgencyAndClient] COLLATE database_default AS [AgencyAndClient], dbo.revenue.[AGENCYCRN] COLLATE database_default AS [AGENCYCRN], dbo.revenue.[CLIENTCRN] COLLATE database_default AS [CLIENTCRN], 
                          [EXTERNALREF] COLLATE database_default AS [EXTERNALREF], [SPOTTYPEDESCRIPTION] COLLATE database_default AS [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], 
                          [Net Value Billable], [Vat], [Total], [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], [JCN] COLLATE database_default AS [JCN], [ORDERVERSIONNO], [CREATEDDATETIME], 
                          [RevMap] COLLATE database_default AS [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], [GlobalTeam] COLLATE database_default AS [GlobalTeam], [BARTERPERCENT], [BarterDiff], 
                          [SourceCompanyName], [Assisted] COLLATE database_default AS [Assisted], dbo.v_SalesExecutiveEmail.EMAILADDRESS, dbo.VET_AgencyCCRN.CCRN AS AgencyCCRN, dbo.VET_ClientCCRN.CCRN
 FROM            [Greens].[dbo].[Revenue] INNER JOIN
                          dbo.v_SalesExecutiveEmail ON dbo.Revenue.SALESEXECNAME COLLATE Latin1_General_CI_AS = dbo.v_SalesExecutiveEmail.SALESEXECNAME INNER JOIN
						  dbo.VET_AgencyCCRN on dbo.Revenue.AGENCYCRN COLLATE Latin1_General_CI_AS = dbo.VET_AgencyCCRN.AGENCYCRN INNER JOIN
						  dbo.VET_ClientCCRN on dbo.Revenue.ClientCRN COLLATE Latin1_General_CI_AS = dbo.VET_ClientCCRN.CLIENTCRN
where [Month] between (DATEADD(month, DATEDIFF(month, 0, getdate()), 0)) and DATEADD(month, 2, getdate()))
UNION ALL
(SELECT        [Category], [ORDERID], [IMPORTED], [ORDERTITLE], [DATASOURCECAMPAIGN], [STATIONGROUPNAME], [Station], [Month], [CAMPAIGN TYPE], [Cost Type], [Greens].[dbo].[RevenueNextYear].[SALESEXECNAME], 
                          [SALESGROUPNAME], dbo.revenuenextyear.[CLIENTNAME], [CLIENTID], dbo.revenuenextyear.[AGENCYNAME], [AgencyAndClient], dbo.revenuenextyear.[AGENCYCRN], dbo.revenuenextyear.[CLIENTCRN], [EXTERNALREF], [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], 
                          [Net Value Billable], [Vat], [Total], [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], [JCN], [ORDERVERSIONNO], [CREATEDDATETIME], [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], 
                          [GlobalTeam], [BARTERPERCENT], [BarterDiff], [SourceCompanyName], [Assisted], dbo.v_SalesExecutiveEmail.EMAILADDRESS, dbo.VET_AgencyCCRN.CCRN AS AgencyCCRN, dbo.VET_ClientCCRN.CCRN
 FROM            [Greens].[dbo].[RevenueNextYear] INNER JOIN
                          dbo.v_SalesExecutiveEmail ON dbo.RevenueNextYear.SALESEXECNAME = dbo.v_SalesExecutiveEmail.SALESEXECNAME INNER JOIN
						  dbo.VET_AgencyCCRN on dbo.RevenueNextYear.AGENCYCRN COLLATE Latin1_General_CI_AS = dbo.VET_AgencyCCRN.AGENCYCRN INNER JOIN
						  dbo.VET_ClientCCRN on dbo.RevenueNextYear.ClientCRN COLLATE Latin1_General_CI_AS = dbo.VET_ClientCCRN.CLIENTCRN
where [Month] between (DATEADD(month, DATEDIFF(month, 0, getdate()), 0)) and DATEADD(month, 2, getdate()))
GO
/****** Object:  View [dbo].[v_RevenueLastYearPlus2]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_RevenueLastYearPlus2] AS
----
SELECT * FROM RevenuePastYears r WITH (NOLOCK) WHERE
r.Month BETWEEN DATEADD(M,-36,(SELECT MIN(month) FROM Revenue)) AND DATEADD(M,-25,(SELECT MIN(month) FROM Revenue))
--
GO
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutiveClientLastYearPlus2]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceGlobalAssistedWinsExecutiveClientLastYearPlus2] AS
SELECT	r.SALESEXECNAME AS SalesExecName
		,r.CLIENTNAME AS ClientName
		,r.Month
		,SUM(r.[Net Value Billable]) AS NetValueBillable
		,SUM(r.ExecTarget) AS ExecTarget
FROM v_RevenueLastYearPlus2 r
WHERE r.Assisted = 'GAW'
GROUP BY r.SALESEXECNAME, r.CLIENTNAME, r.Month

GO
/****** Object:  View [dbo].[v_SourceExecutiveClientLastYearPlus2]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_SourceExecutiveClientLastYearPlus2] AS
----
SELECT	vall.SalesExecName
		,vall.ClientName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
		,SUM(vall.ExecTarget) AS ExecTarget
FROM
(
SELECT	r.SALESEXECNAME AS SalesExecName
		,r.CLIENTNAME AS ClientName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
		,r.ExecTarget
FROM v_RevenueLastYearPlus2 r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesExecName
	,v.CLIENTNAME
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
	,v.ExecTarget
FROM v_SourceGlobalAssistedWinsExecutiveClientLastYearPlus2 v
) vall
GROUP BY vall.SalesExecName, vall.ClientName, vall.Month
--

GO
/****** Object:  View [dbo].[v_SourceCCPTLBillableNetCosts]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceCCPTLBillableNetCosts]
AS
SELECT SALESGROUPNAME, RevSourceName, RevStreamGroupName, RevStreamName, Month, SUM([Net Value Stn Profit]) AS NetValueStnProfit, SUM([Net Value Billable]) AS NetValueBillable
FROM     dbo.Revenue
WHERE  (RevSourceName = 'Local') OR
                  (RevSourceName = 'Agency')
GROUP BY SALESGROUPNAME, RevSourceName, RevStreamGroupName, RevStreamName, Month
GO
/****** Object:  View [dbo].[v_SourceVoiceSRRevenue]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceVoiceSRRevenue]
AS
SELECT r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.RevStreamName AS MappedStreamName, r1.RevStreamName, SUM(v1.NetValueStnProfit) AS NetValueStnProfit, SUM(v1.NetValueBillable) 
                  AS NetValueBillable, DATEDIFF(m,
                      (SELECT DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) AS Expr1), v1.Month) + 1 AS MonthNo,
                      (SELECT MIN(OrderNo) AS Expr1
                       FROM      dbo.ReferenceStreamMapping AS r2
                       WHERE   (MappingStream = r1.MappingStream) AND (MappedStreamName = r1.MappedStreamName) AND (MappingType = 'Revenue')) AS OrderNo
FROM     dbo.ReferenceStreamMapping AS r1 LEFT OUTER JOIN
                  dbo.v_SourceCCPTLBillableNetCosts AS v1 ON v1.RevSourceName = r1.RevSourceName AND v1.RevStreamGroupName = r1.RevStreamGroupName AND (v1.RevStreamName = r1.RevStreamName OR
                  r1.RevStreamName = '')
WHERE  (r1.MappingType = 'Revenue') AND (r1.MappedStreamName = 'Sports Rightsholders')
GROUP BY r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName, r1.RevStreamName
GO
/****** Object:  View [dbo].[v_SourceMasterTarget]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










--
CREATE VIEW [dbo].[v_SourceMasterTarget] AS
----
SELECT vall.SalesGroupName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.TeamTarget) AS TeamTarget
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.TeamTarget
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevSourceName
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.TeamTarget
FROM v_SourceGlobalAssistedWins v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceVoiceSRTarget]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceVoiceSRTarget]
AS
SELECT r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName, SUM(v1.TeamTarget) AS TeamTarget, DATEDIFF(m,
                      (SELECT DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) AS Expr1), v1.Month) + 1 AS MonthNo,
                      (SELECT MIN(OrderNo) AS Expr1
                       FROM      dbo.ReferenceStreamMapping AS r2
                       WHERE   (MappingStream = r1.MappingStream) AND (MappedStreamName = r1.MappedStreamName) AND (MappingType = 'Target')) AS OrderNo
FROM     dbo.ReferenceStreamMapping AS r1 LEFT OUTER JOIN
                  dbo.v_SourceMasterTarget AS v1 ON v1.RevSourceName = r1.RevSourceName AND v1.RevStreamGroupName = r1.RevStreamGroupName AND (v1.RevStreamName = r1.RevStreamName OR
                  r1.RevStreamName = '')
WHERE  (r1.MappingType = 'Target') AND (r1.MappedStreamName IN ('Sports Rightsholders'))
GROUP BY r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName
GO
/****** Object:  View [dbo].[VET_AirtimeFcst]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_AirtimeFcst]
AS
SELECT CAMPAIGNID, CAMPAIGNTITLE, CampaignType, STATIONNAME, SpotCount, BillingPrice, BookedMonth, STATIONID, FriendlyName, HubSpotDealID, SALESEXECNAME, SALESGROUPNAME, EMAILADDRESS, CLIENTNAME, 
                  ACCOUNTSREF, CRN, NetBillingPrice
FROM     CCPLANITLIVE.dbo.VET_AirtimeFcst AS VET_AirtimeFcst_1
GO
/****** Object:  View [dbo].[VET_OffairFcst]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_OffairFcst]
AS
SELECT CAMPAIGNID, CAMPAIGNTITLE, CampaignType, STATIONNAME, OffairDescription, OFFAIRACTIVITYTYPEDESCRIPTION, BookedMonth, OAValue, OAStationAmount, STATIONID, FriendlyName, HubSpotDealID, SALESEXECNAME, 
                  SALESGROUPNAME, EMAILADDRESS, CLIENTNAME, ACCOUNTSREF, CRN, OANetStationAmount
FROM     CCPLANITLIVE.dbo.VET_OffairFcst AS VET_OffairFcst_1
GO
/****** Object:  View [dbo].[VET_ForecastTotal]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_ForecastTotal]
AS
SELECT CAMPAIGNID, CAMPAIGNTITLE, CampaignType, STATIONNAME, STATIONID, 'Airtime' AS CostType, SpotCount, BillingPrice, NetBillingPrice AS StationProfit, BookedMonth, FriendlyName, SalesExecName, SalesGroupName, EmailAddress, 
                  HubSpotDealID, ClientName, AccountsRef, CRN
FROM     dbo.VET_AirtimeFcst
WHERE  HubSpotDealID IS NOT NULL
UNION ALL
SELECT CAMPAIGNID, CAMPAIGNTITLE, CampaignType, STATIONNAME, STATIONID, OFFAIRACTIVITYTYPEDESCRIPTION AS CostType, 0 AS SpotCount, OAValue, OANetStationAmount, BookedMonth, FriendlyName, SalesExecName, 
                  SalesGroupName, EmailAddress, HubSpotDealID, ClientName, AccountsRef, CRN
FROM     dbo.VET_OffairFcst
WHERE  HubSpotDealID IS NOT NULL
GO
/****** Object:  View [dbo].[v_SourceCCPTL]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








--
CREATE VIEW [dbo].[v_SourceCCPTL] AS
----
SELECT vall.SalesGroupName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevSourceName
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
FROM v_SourceGlobalAssistedWins v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[v_SourceGlobalAssistedWinsLastYear] AS
SELECT	r.SALESGROUPNAME as SalesGroupName 
	,rsm.RevSourceName
	,rsm.RevStreamGroupName
	,rsm.RevStreamName
	,r.Month
	,SUM(r.[Net Value Billable]) AS NetValueBillable
	,SUM(r.TeamTarget) AS TeamTarget
FROM v_RevenueLastYear r
LEFT OUTER JOIN ReferenceStreamMapping rsm WITH (NOLOCK) ON rsm.GAWRevStreamName = r.RevStreamName
WHERE r.Assisted = 'GAW'
GROUP BY r.SALESGROUPNAME
	,rsm.RevSourceName
	,rsm.RevStreamGroupName
	,rsm.RevStreamName
	,r.Month


GO
/****** Object:  View [dbo].[v_SourceCCPTLLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











--
CREATE VIEW [dbo].[v_SourceCCPTLLastYear] AS
----
SELECT vall.SalesGroupName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
FROM v_RevenueLastYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevSourceName
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
FROM v_SourceGlobalAssistedWinsLastYear v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceCCPTLLastThisYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-----------------------------------------
CREATE VIEW [dbo].[v_SourceCCPTLLastThisYear] AS
--
SELECT	SalesGroupName
		,RevSourceName
		,RevStreamGroupName
		,RevStreamName
		,Month
		,NetValueStnProfit
FROM v_SourceCCPTLLastYear
UNION
SELECT	SalesGroupName COLLATE Latin1_General_CI_AS
		,RevSourceName COLLATE Latin1_General_CI_AS
		,RevStreamGroupName COLLATE Latin1_General_CI_AS
		,RevStreamName COLLATE Latin1_General_CI_AS
		,Month
		,NetValueStnProfit
FROM v_SourceCCPTL
--
GO
/****** Object:  View [dbo].[v_SourceCCPTLNoAWLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










--
CREATE VIEW [dbo].[v_SourceCCPTLNoAWLastYear] AS
----
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,SUM(r.[Net Value Stn Profit]) AS NetValueStnProfit
FROM v_RevenueLastYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW','CAW')
GROUP BY r.SalesGroupName, r.RevSourceName, r.RevStreamGroupName, r.RevStreamName, r.Month
--
GO
/****** Object:  View [dbo].[v_SourceCCPTLNoAW]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











--
CREATE VIEW [dbo].[v_SourceCCPTLNoAW] AS
----
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,SUM(r.[Net Value Stn Profit]) AS NetValueStnProfit
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW','CAW')
GROUP BY r.SalesGroupName, r.RevSourceName, r.RevStreamGroupName, r.RevStreamName, r.Month
--
GO
/****** Object:  View [dbo].[v_SourceCCPTLNoAWLastThisYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-----------------------------------------
CREATE VIEW [dbo].[v_SourceCCPTLNoAWLastThisYear] AS
--
SELECT	SalesGroupName
		,RevSourceName
		,RevStreamGroupName
		,RevStreamName
		,Month
		,NetValueStnProfit
FROM v_SourceCCPTLNoAWLastYear
UNION
SELECT	SalesGroupName COLLATE Latin1_General_CI_AS
		,RevSourceName COLLATE Latin1_General_CI_AS
		,RevStreamGroupName COLLATE Latin1_General_CI_AS
		,RevStreamName COLLATE Latin1_General_CI_AS
		,Month
		,NetValueStnProfit
FROM v_SourceCCPTLNoAW
--
GO
/****** Object:  View [dbo].[v_SourceCCPTLNoAWNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceCCPTLNoAWNextYear] AS
----
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,SUM(r.[Net Value Stn Profit]) AS NetValueStnProfit
FROM RevenueNextYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW','CAW')
GROUP BY r.SalesGroupName, r.RevSourceName, r.RevStreamGroupName, r.RevStreamName, r.Month
--
GO
/****** Object:  View [dbo].[v_SourceCCPTLNoAWThisNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-----------------------------------------
CREATE VIEW [dbo].[v_SourceCCPTLNoAWThisNextYear] AS
--
SELECT	SalesGroupName
		,RevSourceName
		,RevStreamGroupName
		,RevStreamName
		,Month
		,NetValueStnProfit
FROM v_SourceCCPTLNoAW
UNION
SELECT	SalesGroupName COLLATE Latin1_General_CI_AS
		,RevSourceName COLLATE Latin1_General_CI_AS
		,RevStreamGroupName COLLATE Latin1_General_CI_AS
		,RevStreamName COLLATE Latin1_General_CI_AS
		,Month
		,NetValueStnProfit
FROM v_SourceCCPTLNoAWNextYear
--
GO
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[v_SourceGlobalAssistedWinsNextYear] AS
SELECT	r.SALESGROUPNAME as SalesGroupName 
	,rsm.RevSourceName
	,rsm.RevStreamGroupName
	,rsm.RevStreamName
	,r.Month
	,SUM(r.[Net Value Billable]) AS NetValueBillable
	,SUM(r.TeamTarget) AS TeamTarget
FROM RevenueNextYear r
LEFT OUTER JOIN ReferenceStreamMapping rsm ON rsm.GAWRevStreamName = r.RevStreamName
WHERE r.Assisted = 'GAW'
GROUP BY r.SALESGROUPNAME
	,rsm.RevSourceName
	,rsm.RevStreamGroupName
	,rsm.RevStreamName
	,r.Month


GO
/****** Object:  View [dbo].[v_SourceCCPTLNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











--
CREATE VIEW [dbo].[v_SourceCCPTLNextYear] AS
----
SELECT vall.SalesGroupName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
FROM RevenueNextYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevSourceName'
							)
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
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevSourceName
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
FROM v_SourceGlobalAssistedWinsNextYear v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceCCPTLThisNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-----------------------------------------
CREATE VIEW [dbo].[v_SourceCCPTLThisNextYear] AS
--
SELECT	SalesGroupName
		,RevSourceName
		,RevStreamGroupName
		,RevStreamName
		,Month
		,NetValueStnProfit
FROM v_SourceCCPTL
UNION
SELECT	SalesGroupName COLLATE Latin1_General_CI_AS
		,RevSourceName COLLATE Latin1_General_CI_AS
		,RevStreamGroupName COLLATE Latin1_General_CI_AS
		,RevStreamName COLLATE Latin1_General_CI_AS
		,Month
		,NetValueStnProfit
FROM v_SourceCCPTLNextYear
--
GO
/****** Object:  View [dbo].[v_SourceGlobalBillableWithAW]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[v_SourceGlobalBillableWithAW] AS
--
SELECT	vall.SalesGroupName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.[NetValueBillable]) AS NetValueBillable
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.[Net Value Billable] AS NetValueBillable
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,'Global'
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.NetValueBillable
FROM v_SourceGlobalAssistedWins v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceGlobalBillableWithAWLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[v_SourceGlobalBillableWithAWLastYear] AS
--
SELECT	vall.SalesGroupName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.[NetValueBillable]) AS NetValueBillable
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.[Net Value Billable] AS NetValueBillable
FROM v_RevenueLastYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,'Global'
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.NetValueBillable
FROM v_SourceGlobalAssistedWinsLastYear v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceGlobalBillableWithAWLastThisYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[v_SourceGlobalBillableWithAWLastThisYear] AS
--
SELECT	SalesGroupName
		,RevSourceName
		,RevStreamGroupName
		,RevStreamName
		,Month
		,NetValueBillable
FROM v_SourceGlobalBillableWithAWLastYear
UNION
SELECT	SalesGroupName COLLATE Latin1_General_CI_AS
		,RevSourceName COLLATE Latin1_General_CI_AS
		,RevStreamGroupName COLLATE Latin1_General_CI_AS
		,RevStreamName COLLATE Latin1_General_CI_AS
		,Month
		,NetValueBillable
FROM v_SourceGlobalBillableWithAW
--
GO
/****** Object:  View [dbo].[v_SourceGlobalBillableWithAWNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[v_SourceGlobalBillableWithAWNextYear] AS
--
SELECT	vall.SalesGroupName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.[NetValueBillable]) AS NetValueBillable
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.[Net Value Billable] AS NetValueBillable
FROM RevenueNextYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,'Global'
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.NetValueBillable
FROM v_SourceGlobalAssistedWinsNextYear v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceGlobalBillableWithAWThisNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[v_SourceGlobalBillableWithAWThisNextYear] AS
--
SELECT	SalesGroupName
		,RevSourceName
		,RevStreamGroupName
		,RevStreamName
		,Month
		,NetValueBillable
FROM v_SourceGlobalBillableWithAW
UNION
SELECT	SalesGroupName COLLATE Latin1_General_CI_AS
		,RevSourceName COLLATE Latin1_General_CI_AS
		,RevStreamGroupName COLLATE Latin1_General_CI_AS
		,RevStreamName COLLATE Latin1_General_CI_AS
		,Month
		,NetValueBillable
FROM v_SourceGlobalBillableWithAWNextYear
--
GO
/****** Object:  View [dbo].[v_SourceMasterTargetNoAW]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











--
CREATE VIEW [dbo].[v_SourceMasterTargetNoAW] AS
----
SELECT vall.SalesGroupName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.TeamTarget) AS TeamTarget
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.TeamTarget
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW','CAW')
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevSourceName
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.TeamTarget
FROM v_SourceGlobalAssistedWins v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceMasterTargetNoAWNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












--
CREATE VIEW [dbo].[v_SourceMasterTargetNoAWNextYear] AS
----
SELECT vall.SalesGroupName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.TeamTarget) AS TeamTarget
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.TeamTarget
FROM RevenueNextYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW','CAW')
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevSourceName
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.TeamTarget
FROM v_SourceGlobalAssistedWinsNextYear v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceMasterTargetNoAWThisNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------
CREATE VIEW [dbo].[v_SourceMasterTargetNoAWThisNextYear] AS
--
SELECT	SalesGroupName
		,RevSourceName
		,RevStreamGroupName
		,RevStreamName
		,Month
		,TeamTarget 
FROM v_SourceMasterTargetNoAW
UNION
SELECT	SalesGroupName COLLATE Latin1_General_CI_AS
		,RevSourceName COLLATE Latin1_General_CI_AS
		,RevStreamGroupName COLLATE Latin1_General_CI_AS
		,RevStreamName COLLATE Latin1_General_CI_AS
		,Month
		,TeamTarget
FROM v_SourceMasterTargetNoAWNextYear
--
GO
/****** Object:  View [dbo].[v_SourceMasterTargetNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









--
CREATE VIEW [dbo].[v_SourceMasterTargetNextYear] AS
----
SELECT vall.SalesGroupName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.TeamTarget) AS TeamTarget
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.TeamTarget
FROM RevenueNextYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevSourceName
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.TeamTarget
FROM v_SourceGlobalAssistedWinsNextYear v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceMasterTargetThisNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-------------------------------------------------------------------------
CREATE VIEW [dbo].[v_SourceMasterTargetThisNextYear] AS
--
SELECT	SalesGroupName
		,RevSourceName
		,RevStreamGroupName
		,RevStreamName
		,Month
		,TeamTarget 
FROM v_SourceMasterTarget
UNION
SELECT	SalesGroupName COLLATE Latin1_General_CI_AS
		,RevSourceName COLLATE Latin1_General_CI_AS
		,RevStreamGroupName COLLATE Latin1_General_CI_AS
		,RevStreamName COLLATE Latin1_General_CI_AS
		,Month
		,TeamTarget
FROM v_SourceMasterTargetNextYear
--
GO
/****** Object:  View [dbo].[v_RevenueSummaryBreakdown]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[v_RevenueSummaryBreakdown] AS
--
SELECT	v1.SalesGroupName
		,v1.Month
		,SUM(v1.NetValueStnProfitLocal) AS NetValueStnProfitLocal
		,SUM(v1.TargetLocal) AS TargetLocal
		,SUM(v1.NetValueStnProfitLocalLastYear) AS NetValueStnProfitLocalLastYear
		,SUM(v1.NetValueBillableGlobal) AS NetValueBillableGlobal
		,SUM(v1.TargetGlobal) AS TargetGlobal
		,SUM(v1.NetValueBillableLastYear) AS NetValueBillableLastYear
FROM
(SELECT	v.SalesGroupName
		,v.Month
		,v.NetValueStnProfit AS NetValueStnProfitLocal
		,0 AS TargetLocal
		,0 AS NetValueStnProfitLocalLastYear
		,0 AS NetValueBillableGlobal
		,0 AS TargetGlobal
		,0 AS NetValueBillableLastYear
		FROM v_SourceCCPTLNoAWThisNextYear v WITH (NOLOCK)
		WHERE v.RevSourceName = 'Local'
UNION ALL
SELECT	 v.SalesGroupName
		,v.Month
		,0
		,v.TeamTarget
		,0
		,0
		,0
		,0 
FROM v_SourceMasterTargetNoAWThisNextYear v WITH (NOLOCK)
WHERE v.RevSourceName = 'Local'
UNION ALL
SELECT	 v.SalesGroupName COLLATE Latin1_General_CI_AS
		,DATEADD(YY,1,v.Month)
		,0
		,0
		,v.NetValueStnProfit
		,0
		,0
		,0 
FROM v_SourceCCPTLNoAWLastThisYear v WITH (NOLOCK)
WHERE v.RevSourceName = 'Local'
UNION ALL
SELECT	 v.SalesGroupName COLLATE Latin1_General_CI_AS
		,v.Month
		,0
		,0
		,0
		,v.NetValueBillable
		,0
		,0 
FROM v_SourceGlobalBillableWithAWThisNextYear v WITH (NOLOCK)
WHERE v.RevSourceName = 'Global'
UNION ALL
SELECT	 v.SalesGroupName COLLATE Latin1_General_CI_AS
		,v.Month
		,0
		,0
		,0
		,0
		,v.TeamTarget
		,0 
FROM v_SourceMasterTargetThisNextYear v WITH (NOLOCK)
WHERE v.RevSourceName = 'Global'
UNION ALL
SELECT	 v.SalesGroupName
		,DATEADD(YY,1,v.Month)
		,0
		,0
		,0
		,0
		,0
		,v.NetValueBillable
FROM v_SourceGlobalBillableWithAWLastThisYear v WITH (NOLOCK)
WHERE v.RevSourceName = 'Global'
-----------------------------------------------------------------------------------------------------------------------
UNION ALL
SELECT	'Non Contracted Agency'
		,v.Month
		,v.NetValueStnProfit
		,0
		,0
		,0
		,0
		,0
FROM v_SourceCCPTLThisNextYear v WITH (NOLOCK)
WHERE v.RevSourceName = 'Agency'
UNION ALL
SELECT	'Non Contracted Agency'
		,v.Month
		,0
		,v.TeamTarget
		,0
		,0
		,0
		,0
FROM v_SourceMasterTargetThisNextYear v WITH (NOLOCK)
WHERE v.RevSourceName = 'Agency'
UNION ALL
SELECT	'Non Contracted Agency'
		,DATEADD(YY,1,v.Month)
		,0
		,0
		,v.NetValueStnProfit
		,0
		,0
		,0
FROM v_SourceCCPTLLastThisYear v WITH (NOLOCK)
WHERE v.RevSourceName = 'Agency') v1
GROUP BY v1.SalesGroupName, v1.Month
--
GO
/****** Object:  View [dbo].[v_Tom_Forecast_Current_Campaigns]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Tom_Forecast_Current_Campaigns]
AS
SELECT        CAMPAIGNID
FROM            dbo.VET_ForecastTotal
GROUP BY CAMPAIGNID
GO
/****** Object:  View [dbo].[v_SourceAssistedWinsLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








--
CREATE VIEW [dbo].[v_SourceAssistedWinsLastYear] AS
--
SELECT	r.SalesGroupName
		,r.[CAMPAIGN TYPE] AS CampaignType
		,r.Month
		,SUM(r.[Net Value Stn Profit]) AS NetValueStnProfit
FROM v_RevenueLastYear r WITH (NOLOCK)
WHERE	r.Assisted = 'CAW'
		AND r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'AssistedWins' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
GROUP BY r.SalesGroupName, r.[CAMPAIGN TYPE], r.Month
--
GO
/****** Object:  View [dbo].[VET_RevenueTY_NY]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_RevenueTY_NY]
AS
(SELECT        [Category], [ORDERID], [IMPORTED], [ORDERTITLE] COLLATE database_default AS [ORDERTITLE], [DATASOURCECAMPAIGN] COLLATE database_default AS [DATASOURCECAMPAIGN], 
                          [STATIONGROUPNAME] COLLATE database_default AS [STATIONGROUPNAME], [Station] COLLATE database_default AS [STATION], [Month], [CAMPAIGN TYPE] COLLATE database_default AS [CAMPAIGN TYPE], 
                          [Cost Type] COLLATE database_default AS [Cost Type], [Greens].[dbo].[Revenue].[SALESEXECNAME] COLLATE database_default AS [SALESEXECNAME], 
                          [SALESGROUPNAME] COLLATE database_default AS [SALESGROUPNAME], [CLIENTNAME] COLLATE database_default AS [CLIENTNAME], [CLIENTID], [AGENCYNAME] COLLATE database_default AS [AGENCYNAME], 
                          [AgencyAndClient] COLLATE database_default AS [AgencyAndClient], [AGENCYCRN] COLLATE database_default AS [AGENCYCRN], [CLIENTCRN] COLLATE database_default AS [CLIENTCRN], 
                          [EXTERNALREF] COLLATE database_default AS [EXTERNALREF], [SPOTTYPEDESCRIPTION] COLLATE database_default AS [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], 
                          [Net Value Billable], [Vat], [Total], [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], [JCN] COLLATE database_default AS [JCN], [ORDERVERSIONNO], [CREATEDDATETIME], 
                          [RevMap] COLLATE database_default AS [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], [GlobalTeam] COLLATE database_default AS [GlobalTeam], [BARTERPERCENT], [BarterDiff], 
                          [SourceCompanyName], [Assisted] COLLATE database_default AS [Assisted], dbo.v_SalesExecutiveEmail.EMAILADDRESS
 FROM            [Greens].[dbo].[Revenue] INNER JOIN
                          dbo.v_SalesExecutiveEmail ON dbo.Revenue.SALESEXECNAME COLLATE Latin1_General_CI_AS = dbo.v_SalesExecutiveEmail.SALESEXECNAME)
UNION ALL
(SELECT        [Category], [ORDERID], [IMPORTED], [ORDERTITLE], [DATASOURCECAMPAIGN], [STATIONGROUPNAME], [Station], [Month], [CAMPAIGN TYPE], [Cost Type], [Greens].[dbo].[RevenueNextYear].[SALESEXECNAME], 
                          [SALESGROUPNAME], [CLIENTNAME], [CLIENTID], [AGENCYNAME], [AgencyAndClient], [AGENCYCRN], [CLIENTCRN], [EXTERNALREF], [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], 
                          [Net Value Billable], [Vat], [Total], [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], [JCN], [ORDERVERSIONNO], [CREATEDDATETIME], [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], 
                          [GlobalTeam], [BARTERPERCENT], [BarterDiff], [SourceCompanyName], [Assisted], dbo.v_SalesExecutiveEmail.EMAILADDRESS
 FROM            [Greens].[dbo].[RevenueNextYear] INNER JOIN
                          dbo.v_SalesExecutiveEmail ON dbo.RevenueNextYear.SALESEXECNAME = dbo.v_SalesExecutiveEmail.SALESEXECNAME)
GO
/****** Object:  View [dbo].[VET_GreensRevLines_TYNY]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_GreensRevLines_TYNY]
AS
SELECT R.SALESGROUPNAME, R.RevSourceName, R.RevStreamGroupName, R.RevStreamName, R.Month, M.MappingStream, M.MappedStreamName, M.MappingType, R.[Net Value Stn Profit]
FROM     dbo.VET_RevenueTY_NY AS R INNER JOIN
                  dbo.ReferenceStreamMapping AS M ON R.Category = M.MappingType AND R.RevSourceName = M.RevSourceName AND R.RevStreamGroupName = M.RevStreamGroupName AND R.RevStreamName = M.RevStreamName
GO
/****** Object:  Table [dbo].[vet_tracker_weekly]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[vet_tracker_weekly](
	[Category] [varchar](11) NULL,
	[ORDERID] [int] NULL,
	[IMPORTED] [datetime] NULL,
	[ORDERTITLE] [varchar](128) NULL,
	[DATASOURCECAMPAIGN] [varchar](20) NULL,
	[STATIONGROUPNAME] [varchar](256) NULL,
	[STATION] [varchar](256) NULL,
	[Month] [datetime] NULL,
	[CAMPAIGN TYPE] [varchar](64) NULL,
	[Cost Type] [varchar](64) NULL,
	[SALESEXECNAME] [varchar](128) NULL,
	[SALESGROUPNAME] [varchar](256) NULL,
	[CLIENTNAME] [varchar](128) NULL,
	[CLIENTID] [int] NULL,
	[AGENCYNAME] [varchar](128) NULL,
	[AgencyAndClient] [varchar](259) NULL,
	[AGENCYCRN] [varchar](16) NULL,
	[CLIENTCRN] [varchar](16) NULL,
	[EXTERNALREF] [varchar](32) NULL,
	[SPOTTYPEDESCRIPTION] [varchar](64) NULL,
	[Spots] [int] NULL,
	[Gross Value] [float] NULL,
	[Net Value] [float] NULL,
	[Agency Commission] [float] NULL,
	[Net Value Billable] [float] NULL,
	[Vat] [float] NULL,
	[Total] [float] NULL,
	[Budget] [float] NULL,
	[ExecTarget] [float] NULL,
	[TeamTarget] [float] NULL,
	[Net Value Stn Profit] [float] NULL,
	[JCN] [varchar](16) NULL,
	[ORDERVERSIONNO] [int] NULL,
	[CREATEDDATETIME] [datetime] NULL,
	[RevMap] [varchar](128) NULL,
	[RevStreamName] [varchar](50) NULL,
	[RevStreamGroupName] [varchar](50) NULL,
	[RevSourceName] [varchar](50) NULL,
	[GlobalTeam] [varchar](256) NULL,
	[BARTERPERCENT] [float] NULL,
	[BarterDiff] [float] NULL,
	[SourceCompanyName] [varchar](50) NULL,
	[Assisted] [varchar](11) NULL,
	[EMAILADDRESS] [varchar](64) NULL,
	[copydate] [nvarchar](max) NULL,
	[copydateAsdate]  AS (CONVERT([datetime2],[copydate]))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[VET_LastWeekGreens]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_LastWeekGreens]
AS
SELECT Category, ORDERID, IMPORTED, ORDERTITLE, DATASOURCECAMPAIGN, STATIONGROUPNAME, STATION, Month, [CAMPAIGN TYPE], [Cost Type], SALESEXECNAME, SALESGROUPNAME, CLIENTNAME, CLIENTID, AGENCYNAME, 
                  AgencyAndClient, AGENCYCRN, CLIENTCRN, EXTERNALREF, SPOTTYPEDESCRIPTION, Spots, [Gross Value], [Net Value], [Agency Commission], [Net Value Billable], Vat, Total, [Net Value Stn Profit], JCN, ORDERVERSIONNO, 
                  CREATEDDATETIME, RevMap, RevStreamName, RevStreamGroupName, RevSourceName, Assisted, EMAILADDRESS, copydateAsdate
FROM     dbo.vet_tracker_weekly
WHERE  (SourceCompanyName <> 'Global') AND (Month >=
                      (SELECT DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) AS CurrentYear)) AND (copydateAsdate > GETDATE() - 10) AND (Category = 'Revenue')
GO
/****** Object:  View [dbo].[VET_GreensRevLines_LastWeek]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_GreensRevLines_LastWeek]
AS
SELECT LR.SALESGROUPNAME, LR.RevSourceName, LR.RevStreamGroupName, LR.RevStreamName, LR.Month, M.MappingStream, M.MappedStreamName, M.MappingType, LR.[Net Value Stn Profit], LR.copydateAsdate
FROM     dbo.VET_LastWeekGreens AS LR INNER JOIN
                  dbo.ReferenceStreamMapping AS M ON LR.Category = M.MappingType AND LR.RevSourceName = M.RevSourceName AND LR.RevStreamGroupName = M.RevStreamGroupName AND LR.RevStreamName = M.RevStreamName
GO
/****** Object:  View [dbo].[v_SourceCSTarget]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceCSTarget]
AS
SELECT r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName, r1.RevStreamName, SUM(v1.TeamTarget) AS TeamTarget, DATEDIFF(m,
                      (SELECT DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) AS Expr1), v1.Month) + 1 AS MonthNo,
                      (SELECT MIN(OrderNo) AS Expr1
                       FROM      dbo.ReferenceStreamMapping AS r2
                       WHERE   (MappingStream = r1.MappingStream) AND (MappedStreamName = r1.MappedStreamName) AND (MappingType = 'Target')) AS OrderNo, v1.SalesGroupName
FROM     dbo.ReferenceStreamMapping AS r1 LEFT OUTER JOIN
                  dbo.v_SourceMasterTarget AS v1 ON v1.RevSourceName = r1.RevSourceName AND v1.RevStreamGroupName = r1.RevStreamGroupName AND (v1.RevStreamName = r1.RevStreamName OR
                  r1.RevStreamName = '')
WHERE  (r1.MappingType = 'Target') AND (r1.RevStreamName IN ('SSPN HRA NCA', 'SSPN HRA', 'SSPN Sponsorship', 'SSPN Sponsorship NCA', 'CS Voice Assists', 'CS GoMo Experiential'))
GROUP BY r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName, r1.RevStreamName, v1.SalesGroupName
GO
/****** Object:  View [dbo].[v_SourceCSTotalTarget]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceCSTotalTarget]
AS
SELECT r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName, SUM(v1.TeamTarget) AS TeamTarget, DATEDIFF(m,
                      (SELECT DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) AS Expr1), v1.Month) + 1 AS MonthNo,
                      (SELECT MIN(OrderNo) AS Expr1
                       FROM      dbo.ReferenceStreamMapping AS r2
                       WHERE   (MappingStream = r1.MappingStream) AND (MappedStreamName = r1.MappedStreamName) AND (MappingType = 'Target')) AS OrderNo, v1.RevStreamName
FROM     dbo.ReferenceStreamMapping AS r1 LEFT OUTER JOIN
                  dbo.v_SourceMasterTarget AS v1 ON v1.RevSourceName = r1.RevSourceName AND v1.RevStreamGroupName = r1.RevStreamGroupName AND (v1.RevStreamName = r1.RevStreamName OR
                  r1.RevStreamName = '')
WHERE  (r1.MappingType = 'Target') AND (r1.MappingStream = 'Branded') OR
                  (r1.RevStreamName IN ('SSPN HRA NCA', 'SSPN HRA', 'SSPN Sponsorship', 'SSPN Sponsorship NCA', 'CS Voice Assists', 'CS GoMo Experiential'))
GROUP BY r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName, v1.RevStreamName
GO
/****** Object:  View [dbo].[v_RevenueTargetNCAAssistedWins]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[v_RevenueTargetNCAAssistedWins] as 
---
SELECT r.SalesGroupName 
	,r.RevSourceName
	,r.RevStreamGroupName
	,r.RevStreamName
	,r.Month
	,r.TeamTarget
FROM Revenue r WHERE RevStreamName = 'NCA Assisted Win'
UNION
SELECT r.SalesGroupName COLLATE Latin1_General_CI_AS
	,r.RevSourceName COLLATE Latin1_General_CI_AS
	,r.RevStreamGroupName COLLATE Latin1_General_CI_AS
	,r.RevStreamName COLLATE Latin1_General_CI_AS
	,r.Month
	,r.TeamTarget
FROM RevenueNextYear r WHERE RevStreamName = 'NCA Assisted Win'
--
GO
/****** Object:  View [dbo].[v_SourceExecutiveAssistedWins]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









--
CREATE VIEW [dbo].[v_SourceExecutiveAssistedWins] AS
--
SELECT	r.SalesExecName
		,r.[CAMPAIGN TYPE] AS CampaignType
		,r.Month
		,SUM(r.[Net Value Stn Profit]) AS NetValueStnProfit
FROM Revenue r
WHERE	r.Assisted = 'CAW'
		AND r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'AssistedWins' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
GROUP BY r.SalesExecName, r.[CAMPAIGN TYPE], r.Month
--
GO
/****** Object:  View [dbo].[v_SourceExecutiveGlobalBillable]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[v_SourceExecutiveGlobalBillable] AS
--
SELECT	r.SalesExecName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,SUM(r.[Net Value Billable]) AS NetValueBillable
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1  WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
GROUP BY r.SalesExecName, r.RevSourceName, r.RevStreamGroupName, r.RevStreamName, r.Month
--
GO
/****** Object:  Table [dbo].[ForecastTrackerRevenue]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ForecastTrackerRevenue](
	[ORDERID] [int] NOT NULL,
	[ORDERTITLE] [varchar](128) NULL,
	[DATASOURCECAMPAIGN] [varchar](20) NULL,
	[STATIONGROUPNAME] [varchar](128) NULL,
	[Station] [varchar](128) NULL,
	[Month] [smalldatetime] NULL,
	[CAMPAIGN TYPE] [varchar](64) NULL,
	[Cost Type] [varchar](64) NULL,
	[SpotType] [varchar](64) NULL,
	[CREATEDDATETIME] [datetime] NULL,
	[SALESEXECNAME] [varchar](128) NULL,
	[SALESGROUPNAME] [varchar](256) NULL,
	[CLIENTNAME] [varchar](128) NULL,
	[AGENCYNAME] [varchar](128) NULL,
	[AgencyAndClient] [varchar](259) NULL,
	[Spots] [int] NULL,
	[Gross Value] [float] NULL,
	[Net Value Stn Profit] [float] NULL,
	[Agency Commission] [float] NULL,
	[Net Value Billable] [float] NULL,
	[Vat] [float] NULL,
	[Total] [float] NULL,
	[JCN] [varchar](16) NULL,
	[ORDERVERSIONNO] [int] NULL,
	[BookedDate] [date] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ReferenceSalesGroupBreakdownSFT]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReferenceSalesGroupBreakdownSFT](
	[SalesGroupBreakdownPosition] [int] NULL,
	[SalesGroupBreakdownName] [varchar](30) NULL,
	[SalesGroups] [varchar](500) NULL,
	[AdventureFlag] [char](1) NULL,
UNIQUE NONCLUSTERED 
(
	[SalesGroupBreakdownPosition] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[v_SourceForecastTracker]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[v_SourceForecastTracker] AS
--
SELECT	r.SalesGroupBreakdownName
		,f1.BookedDate
		,f1.Month
		,COALESCE(f1.NetValueStnProfit,0) AS NetValueStnProfit
FROM ReferenceSalesGroupBreakdownSFT r WITH (NOLOCK)
CROSS APPLY 
(SELECT	f.SALESGROUPNAME AS SalesGroupName
		,f.BookedDate
		,f.Month as Month
		,SUM(f.[Net Value Stn Profit]) AS NetValueStnProfit
FROM ForecastTrackerRevenue f WITH (NOLOCK)
WHERE	f.[CAMPAIGN TYPE] IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'ForecastTracker' 
									AND r1.SourceDataName = 'CampaignType'
							)
		AND f.SALESGROUPNAME IN (SELECT Value COLLATE Latin1_General_CI_AS FROM dbo.fn_Split(r.SalesGroups,','))
		-- Exclude House
		AND r.SalesGroupBreakdownName <> 'House'
GROUP BY f.SALESGROUPNAME
		,f.BookedDate
		,f.month
) f1
--
GO
/****** Object:  Table [dbo].[ReferenceNCASalesExecutives]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReferenceNCASalesExecutives](
	[SalesExecName] [varchar](128) NOT NULL,
UNIQUE NONCLUSTERED 
(
	[SalesExecName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[v_SourceNCASalesExecutive]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE VIEW [dbo].[v_SourceNCASalesExecutive] AS
----
SELECT	vall.SalesGroupName
		,vall.SalesExecName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
FROM
(
SELECT	r.SalesGroupName
		,r.SALESEXECNAME AS SalesExecName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName = 'Agency'
		AND r.SALESEXECNAME IN (SELECT  r1.SalesExecName COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceNCASalesExecutives r1 WITH (NOLOCK)
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW','CAW')
UNION ALL
SELECT	r.SalesGroupName
		,'Assisted Executives'
		,r.Month
		,r.[Net Value Stn Profit]
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName = 'Agency'
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted = 'CAW'
) vall
GROUP BY vall.SalesGroupName, vall.SalesExecName, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceNCASalesExecutiveNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[v_SourceNCASalesExecutiveNextYear] AS
----
SELECT	vall.SalesGroupName
		,vall.SalesExecName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
FROM
(
SELECT	r.SalesGroupName
		,r.SALESEXECNAME AS SalesExecName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
FROM RevenueNextYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName = 'Agency'
		AND r.SALESEXECNAME IN (SELECT  r1.SalesExecName COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceNCASalesExecutives AS r1
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW','CAW')
UNION ALL
SELECT	r.SalesGroupName
		,'Assisted Executives'
		,r.Month
		,r.[Net Value Stn Profit]
FROM RevenueNextYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName = 'Agency'
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted = 'CAW'
) vall
GROUP BY vall.SalesGroupName, vall.SalesExecName, vall.Month
--
GO
/****** Object:  Table [dbo].[ForecastSpots]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ForecastSpots](
	[CAMPAIGNID] [int] NULL,
	[PROPOSALID] [int] NULL,
	[STATIONID] [int] NULL,
	[FriendlyName] [nvarchar](200) NULL,
	[DATEBOOKED] [datetime] NULL,
	[PROPOSALSTATIONID] [int] NULL,
	[SCRIPTLENGTH] [smallint] NULL,
	[BROADCASTDATE] [datetime] NULL,
	[SPOTRATE] [float] NULL,
	[SUGGESTEDBROADCASTTIME] [int] NULL,
	[EARLIESTBROADCASTTIME] [int] NULL,
	[LATESTBROADCASTTIME] [int] NULL,
	[TARGETIMPACTS] [float] NULL,
	[BASEIMPACTS] [float] NULL,
	[RATECARDPRICE] [float] NULL,
	[REVENUEIMPACTS] [float] NULL,
	[COSTINGMETHOD] [smallint] NULL,
	[POSITIONINBREAK] [smallint] NULL,
	[BILLINGPRICE] [float] NULL,
	[SCRIPTFACTORID] [int] NULL,
	[BASEDEALPRICE] [float] NULL,
	[BASEDEALFACTOR] [float] NULL,
	[BASEDEALSEASONFACTOR] [float] NULL,
	[CUSTDEALPRICE] [float] NULL,
	[CUSTDEALFACTOR] [float] NULL,
	[CUSTDEALSEASONFACTOR] [float] NULL,
	[BARTERDISCOUNTVALUE] [float] NULL,
	[BARTERSPOTRATE] [float] NULL,
	[SPOTID] [int] NOT NULL,
	[WeekNumber] [int] NULL,
	[WeekCommencing] [datetime] NULL,
	[STARTDATE] [datetime] NULL,
	[ENDDATE] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[v_Tom_Forecast_Months]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Tom_Forecast_Months]
AS
SELECT        CAMPAIGNID, MONTH(BROADCASTDATE) AS Month, CAST(SUM(SPOTRATE) AS decimal(18, 2)) AS SpotRate, CAST(SUM(CUSTDEALPRICE) AS decimal(18, 2)) AS CustDealPrice, CAST(SUM(BASEDEALPRICE) 
                         AS decimal(18, 2)) AS BaseDealPrice, CAST(SUM(BARTERDISCOUNTVALUE) AS decimal(18, 2)) AS BarterDiscountValie, CAST(SUM(BILLINGPRICE) AS decimal(18, 2)) AS BillingPrice
FROM            dbo.ForecastSpots
GROUP BY CAMPAIGNID, MONTH(BROADCASTDATE)
GO
/****** Object:  View [dbo].[VET_CCUKNewBookingsTW]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_CCUKNewBookingsTW]
AS
SELECT [Category], [ORDERID], [IMPORTED], [ORDERTITLE] COLLATE database_default AS [ORDERTITLE], [DATASOURCECAMPAIGN] COLLATE database_default AS [DATASOURCECAMPAIGN], 
                  [STATIONGROUPNAME] COLLATE database_default AS [STATIONGROUPNAME], [Station] COLLATE database_default AS [STATION], [Month], [CAMPAIGN TYPE] COLLATE database_default AS [CAMPAIGN TYPE], 
                  [Cost Type] COLLATE database_default AS [Cost Type], [Greens].[dbo].[Revenue].[SALESEXECNAME] COLLATE database_default AS [SALESEXECNAME], [SALESGROUPNAME] COLLATE database_default AS [SALESGROUPNAME], 
                  [CLIENTNAME] COLLATE database_default AS [CLIENTNAME], [CLIENTID], [AGENCYNAME] COLLATE database_default AS [AGENCYNAME], [AgencyAndClient] COLLATE database_default AS [AgencyAndClient], 
                  [AGENCYCRN] COLLATE database_default AS [AGENCYCRN], [CLIENTCRN] COLLATE database_default AS [CLIENTCRN], [EXTERNALREF] COLLATE database_default AS [EXTERNALREF], 
                  [SPOTTYPEDESCRIPTION] COLLATE database_default AS [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], [Net Value Billable], [Vat], [Total], [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], 
                  [JCN] COLLATE database_default AS [JCN], [ORDERVERSIONNO], [CREATEDDATETIME], [RevMap] COLLATE database_default AS [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], 
                  [GlobalTeam] COLLATE database_default AS [GlobalTeam], [BARTERPERCENT], [BarterDiff], [SourceCompanyName], [Assisted] COLLATE database_default AS [Assisted]
FROM     [Greens].[dbo].[Revenue]
WHERE  RevSourceName in ('Local', 'Agency') AND createddatetime >=
                      (SELECT DISTINCT DATEADD(dd, - 1 - DATEPART(DW, CAST(GETDATE() AS Date)), CAST(GETDATE() AS Date))) AND Category = 'Revenue'
UNION ALL
SELECT [Category], [ORDERID], [IMPORTED], [ORDERTITLE], [DATASOURCECAMPAIGN], [STATIONGROUPNAME], [Station], [Month], [CAMPAIGN TYPE], [Cost Type], [Greens].[dbo].[RevenueNextYear].[SALESEXECNAME], [SALESGROUPNAME], 
                  [CLIENTNAME], [CLIENTID], [AGENCYNAME], [AgencyAndClient], [AGENCYCRN], [CLIENTCRN], [EXTERNALREF], [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], [Net Value Billable], [Vat], [Total], 
                  [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], [JCN], [ORDERVERSIONNO], [CREATEDDATETIME], [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], [GlobalTeam], [BARTERPERCENT], [BarterDiff], 
                  [SourceCompanyName], [Assisted]
FROM     [Greens].[dbo].[RevenueNextYear]
WHERE  RevSourceName in ('Local', 'Agency') AND createddatetime >=
                      (SELECT DISTINCT DATEADD(dd, - 1 - DATEPART(DW, CAST(GETDATE() AS Date)), CAST(GETDATE() AS Date))) AND Category = 'Revenue'
GO
/****** Object:  View [dbo].[VET_GlobalRevenueTYNY]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_GlobalRevenueTYNY]
AS
SELECT [Category], [ORDERID], [IMPORTED], [ORDERTITLE] COLLATE database_default AS [ORDERTITLE], [DATASOURCECAMPAIGN] COLLATE database_default AS [DATASOURCECAMPAIGN], 
                  [STATIONGROUPNAME] COLLATE database_default AS [STATIONGROUPNAME], [Station] COLLATE database_default AS [STATION], [Month], [CAMPAIGN TYPE] COLLATE database_default AS [CAMPAIGN TYPE], 
                  [Cost Type] COLLATE database_default AS [Cost Type], [Greens].[dbo].[Revenue].[SALESEXECNAME] COLLATE database_default AS [SALESEXECNAME], [SALESGROUPNAME] COLLATE database_default AS [SALESGROUPNAME], 
                  [CLIENTNAME] COLLATE database_default AS [CLIENTNAME], [CLIENTID], [AGENCYNAME] COLLATE database_default AS [AGENCYNAME], [AgencyAndClient] COLLATE database_default AS [AgencyAndClient], 
                  [AGENCYCRN] COLLATE database_default AS [AGENCYCRN], [CLIENTCRN] COLLATE database_default AS [CLIENTCRN], [EXTERNALREF] COLLATE database_default AS [EXTERNALREF], 
                  [SPOTTYPEDESCRIPTION] COLLATE database_default AS [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], [Net Value Billable], [Vat], [Total], [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], 
                  [JCN] COLLATE database_default AS [JCN], [ORDERVERSIONNO], [CREATEDDATETIME], [RevMap] COLLATE database_default AS [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], 
                  [GlobalTeam] COLLATE database_default AS [GlobalTeam], [BARTERPERCENT], [BarterDiff], [SourceCompanyName], [Assisted] COLLATE database_default AS [Assisted]
FROM     [Greens].[dbo].[Revenue]
WHERE  RevSourceName = 'Global' AND createddatetime >=
                      (SELECT DISTINCT DATEADD(dd, - 1 - DATEPART(DW, CAST(GETDATE() AS Date)), CAST(GETDATE() AS Date))) AND Category = 'Revenue'
UNION ALL
SELECT [Category], [ORDERID], [IMPORTED], [ORDERTITLE], [DATASOURCECAMPAIGN], [STATIONGROUPNAME], [Station], [Month], [CAMPAIGN TYPE], [Cost Type], [Greens].[dbo].[RevenueNextYear].[SALESEXECNAME], [SALESGROUPNAME], 
                  [CLIENTNAME], [CLIENTID], [AGENCYNAME], [AgencyAndClient], [AGENCYCRN], [CLIENTCRN], [EXTERNALREF], [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], [Net Value Billable], [Vat], [Total], 
                  [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], [JCN], [ORDERVERSIONNO], [CREATEDDATETIME], [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], [GlobalTeam], [BARTERPERCENT], [BarterDiff], 
                  [SourceCompanyName], [Assisted]
FROM     [Greens].[dbo].[RevenueNextYear]
WHERE  RevSourceName = 'Global' AND createddatetime >=
                      (SELECT DISTINCT DATEADD(dd, - 1 - DATEPART(DW, CAST(GETDATE() AS Date)), CAST(GETDATE() AS Date))) AND Category = 'Revenue'
GO
/****** Object:  View [dbo].[VET_LocalReconTYNY]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_LocalReconTYNY]
AS
SELECT [Category], [ORDERID], [IMPORTED], [ORDERTITLE] COLLATE database_default AS [ORDERTITLE], [DATASOURCECAMPAIGN] COLLATE database_default AS [DATASOURCECAMPAIGN], 
                  [STATIONGROUPNAME] COLLATE database_default AS [STATIONGROUPNAME], [Station] COLLATE database_default AS [STATION], [Month], [CAMPAIGN TYPE] COLLATE database_default AS [CAMPAIGN TYPE], 
                  [Cost Type] COLLATE database_default AS [Cost Type], [Greens].[dbo].[Revenue].[SALESEXECNAME] COLLATE database_default AS [SALESEXECNAME], [SALESGROUPNAME] COLLATE database_default AS [SALESGROUPNAME], 
                  [CLIENTNAME] COLLATE database_default AS [CLIENTNAME], [CLIENTID], [AGENCYNAME] COLLATE database_default AS [AGENCYNAME], [AgencyAndClient] COLLATE database_default AS [AgencyAndClient], 
                  [AGENCYCRN] COLLATE database_default AS [AGENCYCRN], [CLIENTCRN] COLLATE database_default AS [CLIENTCRN], [EXTERNALREF] COLLATE database_default AS [EXTERNALREF], 
                  [SPOTTYPEDESCRIPTION] COLLATE database_default AS [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], [Net Value Billable], [Vat], [Total], [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], 
                  [JCN] COLLATE database_default AS [JCN], [ORDERVERSIONNO], [CREATEDDATETIME], [RevMap] COLLATE database_default AS [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], 
                  [GlobalTeam] COLLATE database_default AS [GlobalTeam], [BARTERPERCENT], [BarterDiff], [SourceCompanyName], [Assisted] COLLATE database_default AS [Assisted]
FROM     [Greens].[dbo].[Revenue]
WHERE  RevSourceName IN ('Local', 'Agency') AND Imported >=
                      (SELECT DISTINCT DATEADD(dd, - 5 - DATEPART(DW, CAST(GETDATE() AS Date)), CAST(GETDATE() AS Date))) AND Category = 'Revenue'
UNION ALL
SELECT [Category], [ORDERID], [IMPORTED], [ORDERTITLE], [DATASOURCECAMPAIGN], [STATIONGROUPNAME], [Station], [Month], [CAMPAIGN TYPE], [Cost Type], [Greens].[dbo].[RevenueNextYear].[SALESEXECNAME], [SALESGROUPNAME], 
                  [CLIENTNAME], [CLIENTID], [AGENCYNAME], [AgencyAndClient], [AGENCYCRN], [CLIENTCRN], [EXTERNALREF], [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], [Net Value Billable], [Vat], [Total], 
                  [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], [JCN], [ORDERVERSIONNO], [CREATEDDATETIME], [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], [GlobalTeam], [BARTERPERCENT], [BarterDiff], 
                  [SourceCompanyName], [Assisted]
FROM     [Greens].[dbo].[RevenueNextYear]
WHERE  RevSourceName IN ('Local', 'Agency') AND Imported >=
                      (SELECT DISTINCT DATEADD(dd, - 5 - DATEPART(DW, CAST(GETDATE() AS Date)), CAST(GETDATE() AS Date))) AND Category = 'Revenue'
GO
/****** Object:  View [dbo].[VET_MasterTargetTY_NY]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_MasterTargetTY_NY]
AS
SELECT        [SalesGroupName] COLLATE database_default AS [SalesGroupName], [RevSourceName] COLLATE database_default AS [RevSourceName], [RevStreamGroupName] COLLATE database_default AS [RevStreamGroupName], 
                         [RevStreamName] COLLATE database_default AS [RevStreamName], [Month], [TeamTarget]
FROM            [Greens].[dbo].[v_SourceMasterTarget]
UNION ALL
SELECT        [SalesGroupName], [RevSourceName], [RevStreamGroupName], [RevStreamName], [Month], [TeamTarget]
FROM            [Greens].[dbo].[v_SourceMasterTargetNextYear]
GO
/****** Object:  View [dbo].[v_SourceMasterTargetLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









--
CREATE VIEW [dbo].[v_SourceMasterTargetLastYear] AS
----
SELECT vall.SalesGroupName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.TeamTarget) AS TeamTarget
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.TeamTarget
FROM v_RevenueLastYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'MasterTarget' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevSourceName
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.TeamTarget
FROM v_SourceGlobalAssistedWinsLastYear v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--
GO
/****** Object:  View [dbo].[VET_GreensRevLines_ThisWeek]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_GreensRevLines_ThisWeek]
AS
SELECT R.SALESGROUPNAME, R.RevSourceName, R.RevStreamGroupName, R.RevStreamName, R.Month, M.MappingStream, M.MappedStreamName, M.MappingType, R.[Net Value Stn Profit]
FROM     dbo.VET_RevenueTY_NY AS R INNER JOIN
                  dbo.ReferenceStreamMapping AS M ON R.Category = M.MappingType AND R.RevSourceName = M.RevSourceName AND R.RevStreamGroupName = M.RevStreamGroupName AND R.RevStreamName = M.RevStreamName
WHERE  (R.RevSourceName <> 'Global')
GO
/****** Object:  View [dbo].[v_SourceNCARevenueTargetLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









--
CREATE VIEW [dbo].[v_SourceNCARevenueTargetLastYear] AS
----
SELECT vall.SalesGroupName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.AssistedFlag
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
		,SUM(vall.TeamTarget) AS TeamTarget
FROM
(
SELECT	r.SalesGroupName
		,r.RevStreamGroupName
		,r.RevStreamName
		,(CASE WHEN r.Assisted = 'CAW' THEN 'Y' ELSE 'N' END) AS AssistedFlag
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
		,r.TeamTarget

FROM v_RevenueLastYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
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
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevStreamGroupName
	,v.RevStreamName
	,'N'
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
	,v.TeamTarget
FROM v_SourceGlobalAssistedWinsLastYear v
WHERE v.RevStreamGroupName = 'Agency'
) vall
GROUP BY	vall.SalesGroupName, vall.RevStreamGroupName
			,vall.RevStreamName, vall.AssistedFlag, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceNCARevenueTargetNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









--
CREATE VIEW [dbo].[v_SourceNCARevenueTargetNextYear] AS
----
SELECT vall.SalesGroupName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.AssistedFlag
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
		,SUM(vall.TeamTarget) AS TeamTarget
FROM
(
SELECT	r.SalesGroupName
		,r.RevStreamGroupName
		,r.RevStreamName
		,(CASE WHEN r.Assisted = 'CAW' THEN 'Y' ELSE 'N' END) AS AssistedFlag
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
		,r.TeamTarget

FROM RevenueNextYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
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
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevStreamGroupName
	,v.RevStreamName
	,'N'
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
	,v.TeamTarget
FROM v_SourceGlobalAssistedWinsNextYear v
WHERE v.RevStreamGroupName = 'Agency'
) vall
GROUP BY	vall.SalesGroupName, vall.RevStreamGroupName
			,vall.RevStreamName, vall.AssistedFlag, vall.Month
--
GO
/****** Object:  View [dbo].[v_SourceNCASalesExecutiveLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[v_SourceNCASalesExecutiveLastYear] AS
----
SELECT	vall.SalesGroupName
		,vall.SalesExecName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
FROM
(
SELECT	r.SalesGroupName
		,r.SALESEXECNAME AS SalesExecName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
FROM v_RevenueLastYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName = 'Agency'
		AND r.SALESEXECNAME IN (SELECT  r1.SalesExecName COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceNCASalesExecutives AS r1
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW','CAW')
UNION ALL
SELECT	r.SalesGroupName
		,'Assisted Executives'
		,r.Month
		,r.[Net Value Stn Profit]
FROM v_RevenueLastYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName = 'Agency'
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted = 'CAW'
) vall
GROUP BY vall.SalesGroupName, vall.SalesExecName, vall.Month
--
GO
/****** Object:  View [dbo].[VET_CreateWeeklyBookings]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_CreateWeeklyBookings]
AS
SELECT        Category, ORDERID, IMPORTED, ORDERTITLE, DATASOURCECAMPAIGN, STATIONGROUPNAME, STATION, Month, [CAMPAIGN TYPE], [Cost Type], SALESEXECNAME, SALESGROUPNAME, CLIENTNAME, CLIENTID, 
                         AGENCYNAME, AgencyAndClient, AGENCYCRN, CLIENTCRN, EXTERNALREF, SPOTTYPEDESCRIPTION, Spots, [Gross Value], [Net Value], [Agency Commission], [Net Value Billable], Vat, Total, Budget, ExecTarget, TeamTarget, 
                         [Net Value Stn Profit], JCN, ORDERVERSIONNO, CREATEDDATETIME, RevMap, RevStreamName, RevStreamGroupName, RevSourceName, GlobalTeam, BARTERPERCENT, BarterDiff, SourceCompanyName, Assisted
FROM            dbo.VET_RevenueTY_NY
WHERE        (RevStreamGroupName IN ('SPD', 'Creative', 'MOR', 'Voiceworks', 'GoMo', 'Mindfield')) AND (CREATEDDATETIME >= GETDATE() - 7) AND (CREATEDDATETIME < GETDATE())
GO
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutiveNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[v_SourceGlobalAssistedWinsExecutiveNextYear] AS
SELECT	r.SALESGROUPNAME as SalesGroupName
	,rsm.RevSourceName
	,r.SALESEXECNAME AS SalesExecName
	,r.Month
	,SUM(r.[Net Value Billable]) AS NetValueBillable
	,SUM(r.ExecTarget) AS ExecTarget
FROM RevenueNextYear r
LEFT OUTER JOIN ReferenceStreamMapping rsm ON rsm.GAWRevStreamName = r.RevStreamName
WHERE r.Assisted = 'GAW'
GROUP BY r.SALESGROUPNAME
	,rsm.RevSourceName
	,r.SALESEXECNAME
	,r.Month


GO
/****** Object:  View [dbo].[v_SourceSalesExecutiveNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[v_SourceSalesExecutiveNextYear] AS
----
SELECT	vall.SalesGroupName
		,vall.RevSourceName
		,vall.SalesExecName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
		,SUM(vall.ExecTarget) AS ExecTarget
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.SALESEXECNAME AS SalesExecName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
		,r.ExecTarget
FROM RevenueNextYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevSourceName
	,v.SalesExecName
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
	,v.ExecTarget
FROM v_SourceGlobalAssistedWinsExecutiveNextYear v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.SalesExecName, vall.Month
--

GO
/****** Object:  View [dbo].[VET_RevenueNextYearExecEmail]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_RevenueNextYearExecEmail]
AS
SELECT        dbo.RevenueNextYear.Category, dbo.RevenueNextYear.ORDERID, dbo.RevenueNextYear.IMPORTED, dbo.RevenueNextYear.ORDERTITLE, dbo.RevenueNextYear.DATASOURCECAMPAIGN, 
                         dbo.RevenueNextYear.STATIONGROUPNAME, dbo.RevenueNextYear.Station, dbo.RevenueNextYear.Month, dbo.RevenueNextYear.[CAMPAIGN TYPE], dbo.RevenueNextYear.[Cost Type], 
                         dbo.RevenueNextYear.SALESEXECNAME, dbo.RevenueNextYear.SALESGROUPNAME, dbo.RevenueNextYear.CLIENTNAME, dbo.RevenueNextYear.CLIENTID, dbo.RevenueNextYear.AGENCYNAME, 
                         dbo.RevenueNextYear.AgencyAndClient, dbo.RevenueNextYear.AGENCYCRN, dbo.RevenueNextYear.CLIENTCRN, dbo.RevenueNextYear.EXTERNALREF, dbo.RevenueNextYear.SPOTTYPEDESCRIPTION, 
                         dbo.RevenueNextYear.Spots, dbo.RevenueNextYear.[Gross Value], dbo.RevenueNextYear.[Net Value], dbo.RevenueNextYear.[Agency Commission], dbo.RevenueNextYear.[Net Value Billable], dbo.RevenueNextYear.Vat, 
                         dbo.RevenueNextYear.Total, dbo.RevenueNextYear.Budget, dbo.RevenueNextYear.ExecTarget, dbo.RevenueNextYear.TeamTarget, dbo.RevenueNextYear.[Net Value Stn Profit], dbo.RevenueNextYear.JCN, 
                         dbo.RevenueNextYear.ORDERVERSIONNO, dbo.RevenueNextYear.CREATEDDATETIME, dbo.RevenueNextYear.RevMap, dbo.RevenueNextYear.RevStreamName, dbo.RevenueNextYear.RevStreamGroupName, 
                         dbo.RevenueNextYear.RevSourceName, dbo.RevenueNextYear.GlobalTeam, dbo.RevenueNextYear.BARTERPERCENT, dbo.RevenueNextYear.BarterDiff, dbo.RevenueNextYear.SourceCompanyName, 
                         dbo.RevenueNextYear.Assisted, dbo.v_SalesExecutiveEmail.EMAILADDRESS
FROM            dbo.RevenueNextYear INNER JOIN
                         dbo.v_SalesExecutiveEmail ON dbo.RevenueNextYear.SALESEXECNAME = dbo.v_SalesExecutiveEmail.SALESEXECNAME
GO
/****** Object:  View [dbo].[VET_Revenue3Year]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_Revenue3Year]
AS
(SELECT        [Category], [ORDERID], [IMPORTED], [ORDERTITLE] COLLATE database_default AS [ORDERTITLE], [DATASOURCECAMPAIGN] COLLATE database_default AS [DATASOURCECAMPAIGN], 
                         [STATIONGROUPNAME] COLLATE database_default AS [STATIONGROUPNAME], [Station] COLLATE database_default AS [STATION], [Month], [CAMPAIGN TYPE] COLLATE database_default AS [CAMPAIGN TYPE], 
                         [Cost Type] COLLATE database_default AS [Cost Type], [Greens].[dbo].[Revenue].[SALESEXECNAME] COLLATE database_default AS [SALESEXECNAME], [SALESGROUPNAME] COLLATE database_default AS [SALESGROUPNAME],
                          [CLIENTNAME] COLLATE database_default AS [CLIENTNAME], [CLIENTID], [AGENCYNAME] COLLATE database_default AS [AGENCYNAME], [AgencyAndClient] COLLATE database_default AS [AgencyAndClient], 
                         [AGENCYCRN] COLLATE database_default AS [AGENCYCRN], [CLIENTCRN] COLLATE database_default AS [CLIENTCRN], [EXTERNALREF] COLLATE database_default AS [EXTERNALREF], 
                         [SPOTTYPEDESCRIPTION] COLLATE database_default AS [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], [Net Value Billable], [Vat], [Total], [Budget], [ExecTarget], [TeamTarget], 
                         [Net Value Stn Profit], [JCN] COLLATE database_default AS [JCN], [ORDERVERSIONNO], [CREATEDDATETIME], [RevMap] COLLATE database_default AS [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], 
                         [GlobalTeam] COLLATE database_default AS [GlobalTeam], [BARTERPERCENT], [BarterDiff], [SourceCompanyName], [Assisted] COLLATE database_default AS [Assisted], dbo.v_SalesExecutiveEmail.EMAILADDRESS
FROM            [Greens].[dbo].[Revenue] INNER JOIN
                         dbo.v_SalesExecutiveEmail ON dbo.Revenue.SALESEXECNAME COLLATE Latin1_General_CI_AS = dbo.v_SalesExecutiveEmail.SALESEXECNAME)

UNION ALL

(SELECT        [Category], [ORDERID], [IMPORTED], [ORDERTITLE], [DATASOURCECAMPAIGN], [STATIONGROUPNAME], [Station], [Month], [CAMPAIGN TYPE], [Cost Type], [Greens].[dbo].[RevenueNextYear].[SALESEXECNAME], 
                          [SALESGROUPNAME], [CLIENTNAME], [CLIENTID], [AGENCYNAME], [AgencyAndClient], [AGENCYCRN], [CLIENTCRN], [EXTERNALREF], [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], 
                          [Net Value Billable], [Vat], [Total], [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], [JCN], [ORDERVERSIONNO], [CREATEDDATETIME], [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], 
                          [GlobalTeam], [BARTERPERCENT], [BarterDiff], [SourceCompanyName], [Assisted], dbo.v_SalesExecutiveEmail.EMAILADDRESS
 FROM            [Greens].[dbo].[RevenueNextYear] INNER JOIN
                          dbo.v_SalesExecutiveEmail ON dbo.RevenueNextYear.SALESEXECNAME = dbo.v_SalesExecutiveEmail.SALESEXECNAME)

UNION ALL

(SELECT        dbo.RevenuePastYears.Category, dbo.RevenuePastYears.ORDERID, dbo.RevenuePastYears.IMPORTED, dbo.RevenuePastYears.ORDERTITLE, dbo.RevenuePastYears.DATASOURCECAMPAIGN, 
                         dbo.RevenuePastYears.STATIONGROUPNAME, dbo.RevenuePastYears.Station, dbo.RevenuePastYears.Month, dbo.RevenuePastYears.[CAMPAIGN TYPE], dbo.RevenuePastYears.[Cost Type], 
                         dbo.RevenuePastYears.SALESEXECNAME, dbo.RevenuePastYears.SALESGROUPNAME, dbo.RevenuePastYears.CLIENTNAME, dbo.RevenuePastYears.CLIENTID, dbo.RevenuePastYears.AGENCYNAME, 
                         dbo.RevenuePastYears.AgencyAndClient, dbo.RevenuePastYears.AGENCYCRN, dbo.RevenuePastYears.CLIENTCRN, dbo.RevenuePastYears.EXTERNALREF, dbo.RevenuePastYears.SPOTTYPEDESCRIPTION, 
                         dbo.RevenuePastYears.Spots, dbo.RevenuePastYears.[Gross Value], dbo.RevenuePastYears.[Net Value], dbo.RevenuePastYears.[Agency Commission], dbo.RevenuePastYears.[Net Value Billable], dbo.RevenuePastYears.Vat, 
                         dbo.RevenuePastYears.Total, dbo.RevenuePastYears.Budget, dbo.RevenuePastYears.ExecTarget, dbo.RevenuePastYears.TeamTarget, dbo.RevenuePastYears.[Net Value Stn Profit], dbo.RevenuePastYears.JCN, 
                         dbo.RevenuePastYears.ORDERVERSIONNO, dbo.RevenuePastYears.CREATEDDATETIME, dbo.RevenuePastYears.RevMap, dbo.RevenuePastYears.RevStreamName, dbo.RevenuePastYears.RevStreamGroupName, 
                         dbo.RevenuePastYears.RevSourceName, dbo.RevenuePastYears.GlobalTeam, dbo.RevenuePastYears.BARTERPERCENT, dbo.RevenuePastYears.BarterDiff, dbo.RevenuePastYears.SourceCompanyName, 
                         dbo.RevenuePastYears.Assisted, dbo.v_SalesExecutiveEmail.EMAILADDRESS
FROM            dbo.RevenuePastYears INNER JOIN
                         dbo.v_SalesExecutiveEmail ON dbo.RevenuePastYears.SALESEXECNAME = dbo.v_SalesExecutiveEmail.SALESEXECNAME)
GO
/****** Object:  View [dbo].[v_SourceCSMindfieldTarget]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceCSMindfieldTarget]
AS
SELECT r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName, SUM(v1.TeamTarget) AS TeamTarget, DATEDIFF(m,
                      (SELECT DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) AS Expr1), v1.Month) + 1 AS MonthNo,
                      (SELECT MIN(OrderNo) AS Expr1
                       FROM      dbo.ReferenceStreamMapping AS r2
                       WHERE   (MappingStream = r1.MappingStream) AND (MappedStreamName = r1.MappedStreamName) AND (MappingType = 'Target')) AS OrderNo
FROM     dbo.ReferenceStreamMapping AS r1 LEFT OUTER JOIN
                  dbo.v_SourceMasterTarget AS v1 ON v1.RevSourceName = r1.RevSourceName AND v1.RevStreamGroupName = r1.RevStreamGroupName AND (v1.RevStreamName = r1.RevStreamName OR
                  r1.RevStreamName = '')
WHERE  (r1.MappingType = 'Target') AND (r1.MappedStreamName IN ('SPD Design & Video'))
GROUP BY r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName
GO
/****** Object:  View [dbo].[v_SourceMindfieldTotalTarget]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceMindfieldTotalTarget]
AS
SELECT r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName, SUM(v1.TeamTarget) AS TeamTarget, DATEDIFF(m,
                      (SELECT DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) AS Expr1), v1.Month) + 1 AS MonthNo,
                      (SELECT MIN(OrderNo) AS Expr1
                       FROM      dbo.ReferenceStreamMapping AS r2
                       WHERE   (MappingStream = r1.MappingStream) AND (MappedStreamName = r1.MappedStreamName) AND (MappingType = 'Target')) AS OrderNo, v1.RevStreamName
FROM     dbo.ReferenceStreamMapping AS r1 LEFT OUTER JOIN
                  dbo.v_SourceMasterTarget AS v1 ON v1.RevSourceName = r1.RevSourceName AND v1.RevStreamGroupName = r1.RevStreamGroupName AND (v1.RevStreamName = r1.RevStreamName OR
                  r1.RevStreamName = '')
WHERE  (r1.MappingType = 'Target') AND (r1.MappedStreamName IN ('SPD Design & Video', 'NCA Design', 'Creative', 'Creative Video & Design', 'Outsourced Digital', 'Digital Audience & Management Fee', 'Web & App Development', 'Digital Creative', 
                  'Mindfield Other', 'Mindfield Creative Retainer', 'Research & Insights'))
GROUP BY r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName, v1.RevStreamName
GO
/****** Object:  View [dbo].[VET_AccountsRev2YrStartDates]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_AccountsRev2YrStartDates]
AS
(SELECT        [Category], dbo.Revenue.[ORDERID], dbo.Revenue.[IMPORTED], dbo.Revenue.[ORDERTITLE] COLLATE database_default AS [ORDERTITLE], dbo.Revenue.[DATASOURCECAMPAIGN] COLLATE database_default AS [DATASOURCECAMPAIGN], 
                          [STATIONGROUPNAME] COLLATE database_default AS [STATIONGROUPNAME], [Station] COLLATE database_default AS [STATION], [Month], [CAMPAIGN TYPE] COLLATE database_default AS [CAMPAIGN TYPE], 
                          [Cost Type] COLLATE database_default AS [Cost Type], [Greens].[dbo].[Revenue].[SALESEXECNAME] COLLATE database_default AS [SALESEXECNAME], 
                          [SALESGROUPNAME] COLLATE database_default AS [SALESGROUPNAME], dbo.revenue.[CLIENTNAME] COLLATE database_default AS [CLIENTNAME], dbo.Revenue.[CLIENTID], dbo.revenue.[AGENCYNAME] COLLATE database_default AS [AGENCYNAME], 
                          [AgencyAndClient] COLLATE database_default AS [AgencyAndClient], dbo.revenue.[AGENCYCRN] COLLATE database_default AS [AGENCYCRN], dbo.revenue.[CLIENTCRN] COLLATE database_default AS [CLIENTCRN], 
                          [EXTERNALREF] COLLATE database_default AS [EXTERNALREF], [SPOTTYPEDESCRIPTION] COLLATE database_default AS [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], 
                          [Net Value Billable], [Vat], [Total], [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], dbo.Revenue.[JCN] COLLATE database_default AS [JCN], dbo.Revenue.[ORDERVERSIONNO], dbo.Revenue.[CREATEDDATETIME], 
                          [RevMap] COLLATE database_default AS [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], [GlobalTeam] COLLATE database_default AS [GlobalTeam], dbo.Revenue.[BARTERPERCENT], [BarterDiff], 
                          [SourceCompanyName], [Assisted] COLLATE database_default AS [Assisted], dbo.v_SalesExecutiveEmail.EMAILADDRESS, CCTRAFFICLIVE.dbo.RAORDERS.STARTDATE, dbo.VET_ClientCCRN.CCRN AS ClientCCRN, dbo.VET_AgencyCCRN.CCRN AS AgencyCCRN
 FROM            [Greens].[dbo].[Revenue] INNER JOIN
                          dbo.v_SalesExecutiveEmail ON dbo.Revenue.SALESEXECNAME COLLATE Latin1_General_CI_AS = dbo.v_SalesExecutiveEmail.SALESEXECNAME INNER JOIN
						  CCTRAFFICLIVE.dbo.RAORDERS on CCTRAFFICLIVE.dbo.RAORDERS.ORDERID = dbo.Revenue.OrderID INNER JOIN
						  dbo.VET_AgencyCCRN on dbo.Revenue.AGENCYCRN COLLATE Latin1_General_CI_AS = dbo.VET_AgencyCCRN.AGENCYCRN INNER JOIN
						  dbo.VET_ClientCCRN on dbo.Revenue.ClientCRN COLLATE Latin1_General_CI_AS = dbo.VET_ClientCCRN.CLIENTCRN
 WHERE RevSourceName <> 'Global'                         
						  )
UNION ALL
(SELECT        [Category], dbo.RevenueNextYear.[ORDERID], dbo.RevenueNextYear.[IMPORTED], dbo.RevenueNextYear.[ORDERTITLE], dbo.RevenueNextYear.[DATASOURCECAMPAIGN], [STATIONGROUPNAME], [Station], [Month], [CAMPAIGN TYPE], [Cost Type], [Greens].[dbo].[RevenueNextYear].[SALESEXECNAME], 
                          [SALESGROUPNAME], dbo.RevenueNextYear.[CLIENTNAME], dbo.RevenueNextYear.[CLIENTID], dbo.RevenueNextYear.[AGENCYNAME], [AgencyAndClient], dbo.RevenueNextYear.[AGENCYCRN], dbo.RevenueNextYear.[CLIENTCRN], [EXTERNALREF], [SPOTTYPEDESCRIPTION], [Spots], [Gross Value], [Net Value], [Agency Commission], 
                          [Net Value Billable], [Vat], [Total], [Budget], [ExecTarget], [TeamTarget], [Net Value Stn Profit], dbo.RevenueNextYear.[JCN], dbo.RevenueNextYear.[ORDERVERSIONNO], dbo.RevenueNextYear.[CREATEDDATETIME], [RevMap], [RevStreamName], [RevStreamGroupName], [RevSourceName], 
                          [GlobalTeam], dbo.RevenueNextYear.[BARTERPERCENT], [BarterDiff], [SourceCompanyName], [Assisted], dbo.v_SalesExecutiveEmail.EMAILADDRESS, CCTRAFFICLIVE.dbo.RAORDERS.STARTDATE, dbo.VET_ClientCCRN.CCRN AS ClientCCRN, dbo.VET_AgencyCCRN.CCRN AS AgencyCCRN
 FROM            [Greens].[dbo].[RevenueNextYear] INNER JOIN
                          dbo.v_SalesExecutiveEmail ON dbo.RevenueNextYear.SALESEXECNAME = dbo.v_SalesExecutiveEmail.SALESEXECNAME INNER JOIN
						  CCTRAFFICLIVE.dbo.RAORDERS on CCTRAFFICLIVE.dbo.RAORDERS.ORDERID = dbo.RevenueNextYear.OrderID INNER JOIN
						  dbo.VET_AgencyCCRN on dbo.RevenueNextYear.AGENCYCRN COLLATE Latin1_General_CI_AS = dbo.VET_AgencyCCRN.AGENCYCRN INNER JOIN
						  dbo.VET_ClientCCRN on dbo.RevenueNextYear.ClientCRN COLLATE Latin1_General_CI_AS = dbo.VET_ClientCCRN.CLIENTCRN
 WHERE RevSourceName <> 'Global'   
                           )
GO
/****** Object:  View [dbo].[v_SourceAssistedWins]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








--
CREATE VIEW [dbo].[v_SourceAssistedWins] AS
--
SELECT	r.SalesGroupName
		,r.[CAMPAIGN TYPE] AS CampaignType
		,r.Month
		,SUM(r.[Net Value Stn Profit]) AS NetValueStnProfit
FROM Revenue r
WHERE	r.Assisted = 'CAW'
		AND r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'AssistedWins' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
GROUP BY r.SalesGroupName, r.[CAMPAIGN TYPE], r.Month
--
GO
/****** Object:  View [dbo].[v_SourceAssistedWinsNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







--
CREATE VIEW [dbo].[v_SourceAssistedWinsNextYear] AS
--
SELECT	r.SalesGroupName
		,r.[CAMPAIGN TYPE] AS CampaignType
		,r.Month
		,SUM(r.[Net Value Stn Profit]) AS NetValueStnProfit
FROM RevenueNextYear r
WHERE	r.Assisted = 'CAW'
		AND r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'AssistedWins' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
GROUP BY r.SalesGroupName, r.[CAMPAIGN TYPE], r.Month
--
GO
/****** Object:  View [dbo].[v_SourceAssistedWinsThisNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
----------------------------------------------------
CREATE VIEW [dbo].[v_SourceAssistedWinsThisNextYear] AS
--
SELECT	SalesGroupName
		,CampaignType
		,Month
		,NetValueStnProfit
FROM v_SourceAssistedWins
UNION
SELECT	SalesGroupName COLLATE Latin1_General_CI_AS
		,CampaignType COLLATE Latin1_General_CI_AS
		,Month
		,NetValueStnProfit
FROM v_SourceAssistedWinsNextYear
--
GO
/****** Object:  View [dbo].[v_SourceGlobalBillable]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[v_SourceGlobalBillable] AS
--
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,SUM(r.[Net Value Billable]) AS NetValueBillable
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
GROUP BY r.SalesGroupName, r.RevSourceName, r.RevStreamGroupName, r.RevStreamName, r.Month
--
GO
/****** Object:  View [dbo].[v_SourceGlobalBillableNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[v_SourceGlobalBillableNextYear] AS
--
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,SUM(r.[Net Value Billable]) AS NetValueBillable
FROM RevenueNextYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters AS r1
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
GROUP BY r.SalesGroupName, r.RevSourceName, r.RevStreamGroupName, r.RevStreamName, r.Month
--
GO
/****** Object:  View [dbo].[v_SourceGlobalBillableThisNextYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceGlobalBillableThisNextYear] AS
--
SELECT	SalesGroupName
		,RevSourceName
		,RevStreamGroupName
		,RevStreamName
		,Month
		,NetValueBillable
FROM v_SourceGlobalBillable
UNION
SELECT	SalesGroupName COLLATE Latin1_General_CI_AS
		,RevSourceName COLLATE Latin1_General_CI_AS
		,RevStreamGroupName COLLATE Latin1_General_CI_AS
		,RevStreamName COLLATE Latin1_General_CI_AS
		,Month
		,NetValueBillable
FROM v_SourceGlobalBillableNextYear
--
GO
/****** Object:  View [dbo].[VET_CreateWeeklyBookingsv2]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_CreateWeeklyBookingsv2]
AS
SELECT Category, ORDERID, IMPORTED, ORDERTITLE, DATASOURCECAMPAIGN, STATIONGROUPNAME, STATION, Month, [CAMPAIGN TYPE], [Cost Type], SALESEXECNAME, SALESGROUPNAME, CLIENTNAME, CLIENTID, AGENCYNAME, 
                  AgencyAndClient, AGENCYCRN, CLIENTCRN, EXTERNALREF, SPOTTYPEDESCRIPTION, Spots, [Gross Value], [Net Value], [Agency Commission], [Net Value Billable], Vat, Total, Budget, ExecTarget, TeamTarget, [Net Value Stn Profit], JCN, 
                  ORDERVERSIONNO, CREATEDDATETIME, RevMap, RevStreamName, RevStreamGroupName, RevSourceName, GlobalTeam, BARTERPERCENT, BarterDiff, SourceCompanyName, Assisted
FROM     dbo.VET_RevenueTY_NY
WHERE  (RevStreamGroupName IN ('SPD', 'NCA SPD', 'Creative', 'MOR', 'Voiceworks', 'GoMo', 'Mindfield')) AND (CREATEDDATETIME >=
                      (SELECT DISTINCT DATEADD(dd, - 1 - DATEPART(DW, CAST(GETDATE() AS Date)), CAST(GETDATE() AS Date)) AS Expr1))
GO
/****** Object:  View [dbo].[VET_NCARevenueTYNY]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_NCARevenueTYNY]
AS
(SELECT [Category], 
		[ORDERID], 
		[IMPORTED], 
		[ORDERTITLE] COLLATE database_default AS [ORDERTITLE], 
		[DATASOURCECAMPAIGN] COLLATE database_default AS [DATASOURCECAMPAIGN], 
		[STATIONGROUPNAME] COLLATE database_default AS [STATIONGROUPNAME], 
		[Station] COLLATE database_default AS [STATION], 
		[Month], 
		DATEDIFF(m, '01-01-2022', [Month]) + 1 AS MonthNo,
		[CAMPAIGN TYPE] COLLATE database_default AS [CAMPAIGN TYPE], 
		[Cost Type] COLLATE database_default AS [Cost Type], 
		[Greens].[dbo].[Revenue].[SALESEXECNAME] COLLATE database_default AS [SALESEXECNAME], 
		[SALESGROUPNAME] COLLATE database_default AS [SALESGROUPNAME], 
		[CLIENTNAME] COLLATE database_default AS [CLIENTNAME], 
		[CLIENTID], 
		[AGENCYNAME] COLLATE database_default AS [AGENCYNAME], 
		[AgencyAndClient] COLLATE database_default AS [AgencyAndClient], 
		[AGENCYCRN] COLLATE database_default AS [AGENCYCRN], 
		[CLIENTCRN] COLLATE database_default AS [CLIENTCRN], 
		[EXTERNALREF] COLLATE database_default AS [EXTERNALREF], 
		[SPOTTYPEDESCRIPTION] COLLATE database_default AS [SPOTTYPEDESCRIPTION], 
		[Spots], 
		[Gross Value], 
		[Net Value], 
		[Agency Commission], 
		[Net Value Billable], 
		[Vat], 
		[Total], 
		[Budget], 
		[ExecTarget], 
		[TeamTarget], 
		[Net Value Stn Profit], 
		[JCN] COLLATE database_default AS [JCN], 
		[ORDERVERSIONNO], 
		[CREATEDDATETIME], 
		[RevMap] COLLATE database_default AS [RevMap], 
		[RevStreamName], 
		[RevStreamGroupName], 
		[RevSourceName], 
		[GlobalTeam] COLLATE database_default AS [GlobalTeam], 
		[BARTERPERCENT], 
		[BarterDiff], 
		[SourceCompanyName], 
		[Assisted] COLLATE database_default AS [Assisted], 
		dbo.v_SalesExecutiveEmail.EMAILADDRESS
 FROM      [Greens].[dbo].[Revenue] INNER JOIN
                   dbo.v_SalesExecutiveEmail ON dbo.Revenue.SALESEXECNAME COLLATE Latin1_General_CI_AS = dbo.v_SalesExecutiveEmail.SALESEXECNAME
 WHERE   [RevSourceName] = 'Agency')
UNION ALL
(SELECT [Category], 
		[ORDERID], 
		[IMPORTED], 
		[ORDERTITLE], 
		[DATASOURCECAMPAIGN], 
		[STATIONGROUPNAME], 
		[Station], 
		[Month], 
		DATEDIFF(m, '01-01-2022', [Month]) + 1 AS MonthNo,
		[CAMPAIGN TYPE], 
		[Cost Type], 
		[Greens].[dbo].[RevenueNextYear].[SALESEXECNAME], 
		[SALESGROUPNAME], 
		[CLIENTNAME], 
		[CLIENTID], 
		[AGENCYNAME], 
		[AgencyAndClient], 
		[AGENCYCRN], 
		[CLIENTCRN], 
		[EXTERNALREF], 
		[SPOTTYPEDESCRIPTION], 
		[Spots], 
		[Gross Value], 
		[Net Value], 
		[Agency Commission], 
		[Net Value Billable], 
		[Vat], 
		[Total], 
		[Budget], 
		[ExecTarget], 
		[TeamTarget], 
		[Net Value Stn Profit], 
		[JCN], 
		[ORDERVERSIONNO], 
		[CREATEDDATETIME], 
		[RevMap], 
		[RevStreamName], 
		[RevStreamGroupName], 
		[RevSourceName], 
		[GlobalTeam], 
		[BARTERPERCENT], 
		[BarterDiff], 
		[SourceCompanyName], 
		[Assisted], 
		dbo.v_SalesExecutiveEmail.EMAILADDRESS
 FROM      [Greens].[dbo].[RevenueNextYear] INNER JOIN
                   dbo.v_SalesExecutiveEmail ON dbo.RevenueNextYear.SALESEXECNAME = dbo.v_SalesExecutiveEmail.SALESEXECNAME
 WHERE   [RevSourceName] = 'Agency')
GO
/****** Object:  View [dbo].[v_SourceVoiceSSPNTarget]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceVoiceSSPNTarget]
AS
SELECT r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName, SUM(v1.TeamTarget) AS TeamTarget, DATEDIFF(m,
                      (SELECT DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) AS Expr1), v1.Month) + 1 AS MonthNo,
                      (SELECT MIN(OrderNo) AS Expr1
                       FROM      dbo.ReferenceStreamMapping AS r2
                       WHERE   (MappingStream = r1.MappingStream) AND (MappedStreamName = r1.MappedStreamName) AND (MappingType = 'Target')) AS OrderNo
FROM     dbo.ReferenceStreamMapping AS r1 LEFT OUTER JOIN
                  dbo.v_SourceMasterTarget AS v1 ON v1.RevSourceName = r1.RevSourceName AND v1.RevStreamGroupName = r1.RevStreamGroupName AND (v1.RevStreamName = r1.RevStreamName OR
                  r1.RevStreamName = '')
WHERE  (r1.MappingType = 'Target') AND (r1.MappedStreamName IN ('Voice SSPN', 'SSPN Sponsorship', 'SSPN HRA', 'SSPN Programmatic', 'SSPN Tracking'))
GROUP BY r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName
GO
/****** Object:  View [dbo].[v_SourceVoiceSSPNRevenue]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_SourceVoiceSSPNRevenue]
AS
SELECT r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.RevStreamName AS MappedStreamName, r1.RevStreamName, SUM(v1.NetValueStnProfit) AS NetValueStnProfit, SUM(v1.NetValueBillable) 
                  AS NetValueBillable, DATEDIFF(m,
                      (SELECT DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) AS Expr1), v1.Month) + 1 AS MonthNo,
                      (SELECT MIN(OrderNo) AS Expr1
                       FROM      dbo.ReferenceStreamMapping AS r2
                       WHERE   (MappingStream = r1.MappingStream) AND (MappedStreamName = r1.MappedStreamName) AND (MappingType = 'Revenue')) AS OrderNo
FROM     dbo.ReferenceStreamMapping AS r1 LEFT OUTER JOIN
                  dbo.v_SourceCCPTLBillableNetCosts AS v1 ON v1.RevSourceName = r1.RevSourceName AND v1.RevStreamGroupName = r1.RevStreamGroupName AND (v1.RevStreamName = r1.RevStreamName OR
                  r1.RevStreamName = '')
WHERE  (r1.MappingType = 'Revenue') AND (r1.MappedStreamName = 'Voice SSPN')
GROUP BY r1.MappingStream, v1.Month, r1.RevSourceName, r1.RevStreamGroupName, r1.MappedStreamName, r1.RevStreamName
GO
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutive]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[v_SourceGlobalAssistedWinsExecutive] AS
SELECT	r.SALESGROUPNAME as SalesGroupName
	,rsm.RevSourceName
	,r.SALESEXECNAME AS SalesExecName
	,r.Month
	,SUM(r.[Net Value Billable]) AS NetValueBillable
	,SUM(r.ExecTarget) AS ExecTarget
FROM Revenue r
LEFT OUTER JOIN ReferenceStreamMapping rsm WITH (NOLOCK) ON rsm.GAWRevStreamName = r.RevStreamName
WHERE r.Assisted = 'GAW'
GROUP BY r.SALESGROUPNAME
	,rsm.RevSourceName
	,r.SALESEXECNAME
	,r.Month


GO
/****** Object:  View [dbo].[v_SourceSalesExecutive]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[v_SourceSalesExecutive] AS
----
SELECT	vall.SalesGroupName
		,vall.RevSourceName
		,vall.SalesExecName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
		,SUM(vall.ExecTarget) AS ExecTarget
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.SALESEXECNAME AS SalesExecName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
		,r.ExecTarget
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'SalesExecutive' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevSourceName
	,v.SalesExecName
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
	,v.ExecTarget
FROM v_SourceGlobalAssistedWinsExecutive v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.SalesExecName, vall.Month
--

GO
/****** Object:  View [dbo].[v_SourceGlobalBillableLastYear]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[v_SourceGlobalBillableLastYear] AS
--
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,SUM(r.[Net Value Billable]) AS NetValueBillable
FROM v_RevenueLastYear r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'GlobalBillable' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
GROUP BY r.SalesGroupName, r.RevSourceName, r.RevStreamGroupName, r.RevStreamName, r.Month
--
GO
/****** Object:  View [dbo].[v_Ema_SourceCCPTL]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









--
CREATE VIEW [dbo].[v_Ema_SourceCCPTL] AS
----
SELECT vall.SalesGroupName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
		,SUM(vall.NetValueBillable) AS NetValueBillable
FROM
(
SELECT	r.SalesGroupName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
		,r.[Net Value Billable] AS NetValueBillable
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesGroupName 
	,v.RevSourceName
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
	,v.NetValueBillable AS NetValueBillable
FROM v_SourceGlobalAssistedWins v
) vall
GROUP BY vall.SalesGroupName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--

GO
/****** Object:  View [dbo].[v_SourceExecutiveCCPTL]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









--
CREATE VIEW [dbo].[v_SourceExecutiveCCPTL] AS
----
SELECT vall.SalesExecName
		,vall.RevSourceName
		,vall.RevStreamGroupName
		,vall.RevStreamName
		,vall.Month
		,SUM(vall.NetValueStnProfit) AS NetValueStnProfit
FROM
(
SELECT	r.SalesExecName
		,r.RevSourceName
		,r.RevStreamGroupName
		,r.RevStreamName
		,r.Month
		,r.[Net Value Stn Profit] AS NetValueStnProfit
FROM Revenue r
WHERE	r.SALESGROUPNAME IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SalesGroupName'
							)
		AND r.RevSourceName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevSourceName'
							)
		AND r.RevStreamGroupName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamGroupName'
							)
		AND r.RevStreamName IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'RevStreamName'
							)
		AND r.SPOTTYPEDESCRIPTION IN (SELECT SourceDataValueIncluded COLLATE Latin1_General_CI_AS
							FROM Greens.dbo.ReferenceSourceFilters r1 WITH (NOLOCK)
							WHERE	r1.SourceType = 'CCPTL' 
									AND r1.SourceDataName = 'SpotTypeDescription'
							)
		AND r.Assisted NOT IN ('GAW')
UNION ALL
SELECT	v.SalesExecName
	,v.RevSourceName
	,v.RevStreamGroupName
	,v.RevStreamName
	,v.Month
	,v.NetValueBillable AS NetValueStnProfit
FROM v_SourceExecutiveGlobalAssistedWins v
) vall
GROUP BY vall.SalesExecName, vall.RevSourceName, vall.RevStreamGroupName, vall.RevStreamName, vall.Month
--
GO
/****** Object:  View [dbo].[VET_CampaignDates]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_CampaignDates]
AS
SELECT O.DATASOURCECAMPAIGN, O.STARTDATE, O.ENDDATE, O.FIRSTSPOTDATE, O.LASTSPOTDATE, C.CLIENTNAME, C.CLIENTCRN, C.ACCOUNTSREF, O.ORDERID
FROM     CCTRAFFICLIVE.dbo.RAORDERS AS O WITH (NOLOCK) INNER JOIN
                  CCTRAFFICLIVE.dbo.RACLIENTS AS C WITH (NOLOCK) ON O.CLIENTID = C.CLIENTID
WHERE  (O.ENDDATE >= '01-01-2023') AND (O.DATASOURCEID = 1)
GO
/****** Object:  View [dbo].[VET_DealIDDupesDetail]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_DealIDDupesDetail]
AS
SELECT cp.CAMPAIGNID, C.CLIENTNAME, P.STARTDATE, P.ENDDATE, cp.HSDEALID, C.CLIENTID
FROM     CCPLANITLIVE.dbo.RPCAMPAIGNS AS cp INNER JOIN
                  CCPLANITLIVE.dbo.RPCMPSTREAMS AS CS WITH (nolock) ON CS.CAMPAIGNID = cp.CAMPAIGNID INNER JOIN
                  CCPLANITLIVE.dbo.PROPOSAL AS P WITH (nolock) ON P.PROPOSALID = CS.BOOKEDPROPOSALID INNER JOIN
                  CCPLANITLIVE.dbo.CLIENT AS C ON cp.CLIENTID = C.CLIENTID INNER JOIN
                  CCPLANITLIVE.dbo.AGENCY AS A ON cp.AGENCYID = A.AGENCYID
WHERE  (cp.HSDEALID IS NOT NULL)
GO
/****** Object:  View [dbo].[VET_HSDealIDDuplicates]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_HSDealIDDuplicates]
AS
SELECT CP.HSDEALID, COUNT(*) AS [No of Campaigns]
FROM     CCPLANITLIVE.dbo.RPCAMPAIGNS AS CP INNER JOIN
                  CCPLANITLIVE.dbo.RPCMPSTREAMS AS CS WITH (nolock) ON CS.CAMPAIGNID = CP.CAMPAIGNID INNER JOIN
                  CCPLANITLIVE.dbo.PROPOSAL AS P WITH (nolock) ON P.PROPOSALID = CS.BOOKEDPROPOSALID
WHERE  (CP.HSDEALID <> '')
GROUP BY CP.HSDEALID
HAVING (COUNT(*) >= 2)
GO
/****** Object:  View [dbo].[VET_InventoryFcst]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_InventoryFcst]
AS
SELECT        CAMPAIGNID, CAMPAIGNTITLE, CampaignType, STATIONNAME, SCRIPTLENGTH, SpotCount, TotalSeconds, BillingPrice, BookedMonth, STATIONID, FriendlyName, HubSpotDealID, SALESEXECNAME, SALESGROUPNAME, 
                         EMAILADDRESS, CLIENTNAME, ACCOUNTSREF, CRN
FROM            CCPLANITLIVE.dbo.VET_InventoryForecast AS VET_InventoryFcst
GO
/****** Object:  View [dbo].[VET_LiveReads]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_LiveReads]
AS
SELECT c.CLIENTNAME, o.DATASOURCECAMPAIGN, o.ORDERID, s.STATIONNAME, o.CREATEDDATETIME, ot.TYPEDESCRIPTION, os.ORDERDATE, os.ORDERSTARTTIME, os.ORDERENDTIME, t.LOGNAME, os.SPOTLENGTH, os.SCRIPTFACTOR, 
                  os.DAYPARTNAME, o.ORDERTITLE, slsg.SALESGROUPNAME, se.SALESEXECNAME
FROM     CCTRAFFICLIVE.dbo.RAORDERSPOTS AS os INNER JOIN
                  CCTRAFFICLIVE.dbo.RASCHEDULEDSPOTS AS ss WITH (nolock) ON os.ORDERSPOTID = ss.ORDERSPOTID INNER JOIN
                  CCTRAFFICLIVE.dbo.RAORDERS AS o WITH (nolock) ON os.ORDERID = o.ORDERID INNER JOIN
                  CCTRAFFICLIVE.dbo.RACLIENTS AS c WITH (nolock) ON o.CLIENTID = c.CLIENTID INNER JOIN
                  CCTRAFFICLIVE.dbo.RAORDERTYPES AS ot WITH (nolock) ON o.ORDERTYPEID = ot.ORDERTYPEID INNER JOIN
                  CCTRAFFICLIVE.dbo.RASPOTTYPES AS st WITH (nolock) ON os.SPOTTYPEID = st.SPOTTYPEID INNER JOIN
                  CCTRAFFICLIVE.dbo.RATRANSMITTERS AS t WITH (nolock) ON t.TRANSMITTERID = ss.TRANSMITTERID INNER JOIN
                  CCTRAFFICLIVE.dbo.RASTATIONS AS s WITH (nolock) ON o.STATIONID = s.STATIONID INNER JOIN
                  CCTRAFFICLIVE.dbo.RASTATIONGROUPS AS sg WITH (nolock) ON s.STATIONGROUPID = sg.STATIONGROUPID INNER JOIN
                  CCTRAFFICLIVE.dbo.RASALESEXECS AS se WITH (nolock) ON o.SALESEXECID = se.SALESEXECID INNER JOIN
                  CCTRAFFICLIVE.dbo.RASALESGROUP AS slsg WITH (nolock) ON se.SALESGROUPID = slsg.SALESGROUPID
WHERE  (os.ORDERDATE >= GETDATE()) AND (ss.SPOTSTATUSID NOT IN (2, 3, 8, 12, 6)) AND (st.SPOTTYPEID = 36)
GO
/****** Object:  View [dbo].[VET_OffPeakUsage]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_OffPeakUsage]
AS
SELECT        ORDERID, SalesExec, Client, Station, OrderType, Created, StartDate, EndDate, TotalSpots, OffpeakSpots, Percentage
FROM            CCTRAFFICLIVE.dbo.VET_OffPeakUsage
GO
/****** Object:  View [dbo].[VET_OrderStartDate2Yr]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_OrderStartDate2Yr]
AS
SELECT DISTINCT DATASOURCECAMPAIGN, ORDERID, STARTDATE
FROM     CCTRAFFICLIVE.dbo.RAORDERS AS o WITH (NOLOCK)
WHERE  (STARTDATE <=
                      (SELECT DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) + 2, - 1) AS Expr1)) AND (ENDDATE >=
                      (SELECT DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) AS Expr1)) AND (DATASOURCEID = 1)
GO
/****** Object:  Table [dbo].[BenchmarkRatesforCPT]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BenchmarkRatesforCPT](
	[StationID] [int] NOT NULL,
	[StationName] [nvarchar](50) NOT NULL,
	[AirtimeBenchmark] [float] NOT NULL,
	[SponsBenchmark] [float] NOT NULL,
	[PricingType] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_BenchmarkRatesforCPT] PRIMARY KEY CLUSTERED 
(
	[StationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[briefs]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[briefs](
	[PartitionKey] [nvarchar](max) NULL,
	[RowKey] [nvarchar](max) NULL,
	[Timestamp] [datetimeoffset](7) NULL,
	[breifCreated] [nvarchar](max) NULL,
	[breifDue] [nvarchar](max) NULL,
	[briefId] [nvarchar](max) NULL,
	[companyCCRN] [nvarchar](max) NULL,
	[companyCategory] [nvarchar](max) NULL,
	[companyName] [nvarchar](max) NULL,
	[companyTier] [nvarchar](max) NULL,
	[dealId] [nvarchar](max) NULL,
	[dealName] [nvarchar](max) NULL,
	[salesExecEmail] [nvarchar](max) NULL,
	[teamId] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ForecastTrackerMonthEnd]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ForecastTrackerMonthEnd](
	[SalesGroupBreakdownName] [varchar](30) NULL,
	[WeekCommencing] [date] NULL,
	[Month] [date] NULL,
	[Forecast] [numeric](10, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ForecastTrackerWeeklyForecast]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ForecastTrackerWeeklyForecast](
	[SalesGroupBreakdownName] [varchar](30) NULL,
	[WeekCommencing] [date] NULL,
	[Month] [date] NULL,
	[Forecast] [numeric](10, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[gomoRevenue]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[gomoRevenue](
	[hashid] [nvarchar](max) NULL,
	[alertsent] [bit] NULL,
	[ORDERID] [int] NULL,
	[IMPORTED] [datetime] NULL,
	[ORDERTITLE] [varchar](128) NULL,
	[DATASOURCECAMPAIGN] [varchar](20) NULL,
	[STATIONGROUPNAME] [varchar](256) NULL,
	[Station] [varchar](256) NULL,
	[Month] [datetime] NULL,
	[CAMPAIGN TYPE] [varchar](64) NULL,
	[Cost Type] [varchar](64) NULL,
	[SALESEXECNAME] [varchar](128) NULL,
	[SALESGROUPNAME] [varchar](256) NULL,
	[CLIENTNAME] [varchar](128) NULL,
	[CLIENTID] [int] NULL,
	[AGENCYNAME] [varchar](128) NULL,
	[AgencyAndClient] [varchar](259) NULL,
	[AGENCYCRN] [varchar](16) NULL,
	[CLIENTCRN] [varchar](16) NULL,
	[EXTERNALREF] [varchar](32) NULL,
	[SPOTTYPEDESCRIPTION] [varchar](64) NULL,
	[Spots] [int] NULL,
	[Gross Value] [float] NULL,
	[Net Value] [float] NULL,
	[Agency Commission] [float] NULL,
	[Net Value Billable] [float] NULL,
	[Vat] [float] NULL,
	[Total] [float] NULL,
	[Budget] [float] NULL,
	[ExecTarget] [float] NULL,
	[TeamTarget] [float] NULL,
	[Net Value Stn Profit] [float] NULL,
	[JCN] [varchar](16) NULL,
	[ORDERVERSIONNO] [int] NULL,
	[CREATEDDATETIME] [datetime] NULL,
	[RevMap] [varchar](128) NULL,
	[RevStreamName] [varchar](50) NULL,
	[RevStreamGroupName] [varchar](50) NULL,
	[RevSourceName] [varchar](50) NULL,
	[GlobalTeam] [varchar](256) NULL,
	[BARTERPERCENT] [float] NULL,
	[BarterDiff] [float] NULL,
	[SourceCompanyName] [varchar](50) NULL,
	[Assisted] [varchar](11) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ReferenceGPStationMapping]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReferenceGPStationMapping](
	[StationGroupID] [int] NOT NULL,
	[GPStationID] [varchar](5) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[StationGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ReferenceNominalCodeMapping]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReferenceNominalCodeMapping](
	[OrderTypeID_OATypeID] [varchar](15) NOT NULL,
	[NominalCode] [varchar](15) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[OrderTypeID_OATypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ReferenceRevenueSummaryTargetPercentage]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReferenceRevenueSummaryTargetPercentage](
	[MonthInFuture] [int] NOT NULL,
	[WeekNo] [int] NOT NULL,
	[TargetPercentage] [float] NULL,
PRIMARY KEY CLUSTERED 
(
	[MonthInFuture] ASC,
	[WeekNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ReferenceSalesGroupBreakdown]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReferenceSalesGroupBreakdown](
	[SalesGroupBreakdownName] [varchar](30) NULL,
	[SalesGroups] [varchar](500) NULL,
	[ExecutiveExcludeFlag] [varchar](1) NULL,
UNIQUE NONCLUSTERED 
(
	[SalesGroupBreakdownName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ReferenceSalesGroupBreakdownMonthly]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReferenceSalesGroupBreakdownMonthly](
	[SalesGroupBreakdownPosition] [int] NULL,
	[SalesGroupBreakdownName] [varchar](30) NULL,
	[SalesGroups] [varchar](500) NULL,
UNIQUE NONCLUSTERED 
(
	[SalesGroupBreakdownPosition] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RevenueNextYearStaging]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RevenueNextYearStaging](
	[Category] [varchar](11) NOT NULL,
	[ORDERID] [int] NOT NULL,
	[IMPORTED] [datetime] NULL,
	[ORDERTITLE] [varchar](128) NULL,
	[DATASOURCECAMPAIGN] [varchar](20) NULL,
	[STATIONGROUPNAME] [varchar](256) NULL,
	[Station] [varchar](256) NULL,
	[Month] [datetime] NULL,
	[CAMPAIGN TYPE] [varchar](64) NULL,
	[Cost Type] [varchar](64) NULL,
	[SALESEXECNAME] [varchar](128) NULL,
	[SALESGROUPNAME] [varchar](256) NULL,
	[CLIENTNAME] [varchar](128) NULL,
	[CLIENTID] [int] NULL,
	[AGENCYNAME] [varchar](128) NULL,
	[AgencyAndClient] [varchar](259) NULL,
	[AGENCYCRN] [varchar](16) NULL,
	[CLIENTCRN] [varchar](16) NULL,
	[EXTERNALREF] [varchar](32) NULL,
	[SPOTTYPEDESCRIPTION] [varchar](64) NULL,
	[Spots] [int] NULL,
	[Gross Value] [float] NULL,
	[Net Value] [float] NULL,
	[Agency Commission] [float] NULL,
	[Net Value Billable] [float] NULL,
	[Vat] [float] NULL,
	[Total] [float] NULL,
	[Budget] [float] NULL,
	[ExecTarget] [float] NOT NULL,
	[TeamTarget] [float] NOT NULL,
	[Net Value Stn Profit] [float] NULL,
	[JCN] [varchar](16) NULL,
	[ORDERVERSIONNO] [int] NULL,
	[CREATEDDATETIME] [datetime] NULL,
	[RevMap] [varchar](128) NULL,
	[RevStreamName] [varchar](50) NULL,
	[RevStreamGroupName] [varchar](50) NULL,
	[RevSourceName] [varchar](50) NULL,
	[GlobalTeam] [varchar](256) NULL,
	[BARTERPERCENT] [float] NULL,
	[BarterDiff] [float] NULL,
	[SourceCompanyName] [varchar](50) NULL,
	[Assisted] [varchar](11) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RevenueStaging]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RevenueStaging](
	[Category] [varchar](11) NOT NULL,
	[ORDERID] [int] NOT NULL,
	[IMPORTED] [datetime] NULL,
	[ORDERTITLE] [varchar](128) NULL,
	[DATASOURCECAMPAIGN] [varchar](20) NULL,
	[STATIONGROUPNAME] [varchar](256) NULL,
	[Station] [varchar](256) NULL,
	[Month] [datetime] NULL,
	[CAMPAIGN TYPE] [varchar](64) NULL,
	[Cost Type] [varchar](64) NULL,
	[SALESEXECNAME] [varchar](128) NULL,
	[SALESGROUPNAME] [varchar](256) NULL,
	[CLIENTNAME] [varchar](128) NULL,
	[CLIENTID] [int] NULL,
	[AGENCYNAME] [varchar](128) NULL,
	[AgencyAndClient] [varchar](259) NULL,
	[AGENCYCRN] [varchar](16) NULL,
	[CLIENTCRN] [varchar](16) NULL,
	[EXTERNALREF] [varchar](32) NULL,
	[SPOTTYPEDESCRIPTION] [varchar](64) NULL,
	[Spots] [int] NULL,
	[Gross Value] [float] NULL,
	[Net Value] [float] NULL,
	[Agency Commission] [float] NULL,
	[Net Value Billable] [float] NULL,
	[Vat] [float] NULL,
	[Total] [float] NULL,
	[Budget] [float] NULL,
	[ExecTarget] [float] NOT NULL,
	[TeamTarget] [float] NOT NULL,
	[Net Value Stn Profit] [float] NULL,
	[JCN] [varchar](16) NULL,
	[ORDERVERSIONNO] [int] NULL,
	[CREATEDDATETIME] [datetime] NULL,
	[RevMap] [varchar](128) NULL,
	[RevStreamName] [varchar](50) NULL,
	[RevStreamGroupName] [varchar](50) NULL,
	[RevSourceName] [varchar](50) NULL,
	[GlobalTeam] [varchar](256) NULL,
	[BARTERPERCENT] [float] NULL,
	[BarterDiff] [float] NULL,
	[SourceCompanyName] [varchar](50) NULL,
	[Assisted] [varchar](11) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[xxRevenue]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[xxRevenue](
	[Category] [varchar](11) NOT NULL,
	[ORDERID] [int] NOT NULL,
	[IMPORTED] [datetime] NULL,
	[ORDERTITLE] [varchar](128) NULL,
	[DATASOURCECAMPAIGN] [varchar](20) NULL,
	[STATIONGROUPNAME] [varchar](256) NULL,
	[Station] [varchar](256) NULL,
	[Month] [datetime] NULL,
	[CAMPAIGN TYPE] [varchar](64) NULL,
	[Cost Type] [varchar](64) NULL,
	[SALESEXECNAME] [varchar](128) NULL,
	[SALESGROUPNAME] [varchar](256) NULL,
	[CLIENTNAME] [varchar](128) NULL,
	[CLIENTID] [int] NULL,
	[AGENCYNAME] [varchar](128) NULL,
	[AgencyAndClient] [varchar](259) NULL,
	[AGENCYCRN] [varchar](16) NULL,
	[CLIENTCRN] [varchar](16) NULL,
	[EXTERNALREF] [varchar](32) NULL,
	[SPOTTYPEDESCRIPTION] [varchar](64) NULL,
	[Spots] [int] NULL,
	[Gross Value] [float] NULL,
	[Net Value] [float] NULL,
	[Agency Commission] [float] NULL,
	[Net Value Billable] [float] NULL,
	[Vat] [float] NULL,
	[Total] [float] NULL,
	[Budget] [float] NULL,
	[ExecTarget] [float] NOT NULL,
	[TeamTarget] [float] NOT NULL,
	[Net Value Stn Profit] [float] NULL,
	[JCN] [varchar](16) NULL,
	[ORDERVERSIONNO] [int] NULL,
	[CREATEDDATETIME] [datetime] NULL,
	[RevMap] [varchar](128) NULL,
	[RevStreamName] [varchar](50) NULL,
	[RevStreamGroupName] [varchar](50) NULL,
	[RevSourceName] [varchar](50) NULL,
	[GlobalTeam] [varchar](256) NULL,
	[BARTERPERCENT] [float] NULL,
	[BarterDiff] [float] NULL,
	[SourceCompanyName] [varchar](50) NULL,
	[Assisted] [varchar](11) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[xxRevenueStaging]    Script Date: 18/09/2024 16:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[xxRevenueStaging](
	[Category] [varchar](11) NOT NULL,
	[ORDERID] [int] NOT NULL,
	[IMPORTED] [datetime] NULL,
	[ORDERTITLE] [varchar](128) NULL,
	[DATASOURCECAMPAIGN] [varchar](20) NULL,
	[STATIONGROUPNAME] [varchar](256) NULL,
	[Station] [varchar](256) NULL,
	[Month] [datetime] NULL,
	[CAMPAIGN TYPE] [varchar](64) NULL,
	[Cost Type] [varchar](64) NULL,
	[SALESEXECNAME] [varchar](128) NULL,
	[SALESGROUPNAME] [varchar](256) NULL,
	[CLIENTNAME] [varchar](128) NULL,
	[CLIENTID] [int] NULL,
	[AGENCYNAME] [varchar](128) NULL,
	[AgencyAndClient] [varchar](259) NULL,
	[AGENCYCRN] [varchar](16) NULL,
	[CLIENTCRN] [varchar](16) NULL,
	[EXTERNALREF] [varchar](32) NULL,
	[SPOTTYPEDESCRIPTION] [varchar](64) NULL,
	[Spots] [int] NULL,
	[Gross Value] [float] NULL,
	[Net Value] [float] NULL,
	[Agency Commission] [float] NULL,
	[Net Value Billable] [float] NULL,
	[Vat] [float] NULL,
	[Total] [float] NULL,
	[Budget] [float] NULL,
	[ExecTarget] [float] NOT NULL,
	[TeamTarget] [float] NOT NULL,
	[Net Value Stn Profit] [float] NULL,
	[JCN] [varchar](16) NULL,
	[ORDERVERSIONNO] [int] NULL,
	[CREATEDDATETIME] [datetime] NULL,
	[RevMap] [varchar](128) NULL,
	[RevStreamName] [varchar](50) NULL,
	[RevStreamGroupName] [varchar](50) NULL,
	[RevSourceName] [varchar](50) NULL,
	[GlobalTeam] [varchar](256) NULL,
	[BARTERPERCENT] [float] NULL,
	[BarterDiff] [float] NULL,
	[SourceCompanyName] [varchar](50) NULL,
	[Assisted] [varchar](11) NULL
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[ExecutiveRevenueBreakdown]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[ForecastTrackerBreakdown]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[ForecastTrackerRefresh]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[GreensRefresh]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[GreensRefreshNextYear]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[GreensRefreshNextYearStaging]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[GreensRefreshPastYears]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[GreensRefreshStaging]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[NCARevenueBreakdownDrilldown]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[NCARevenueBreakdownDrilldownLastYear]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[NCARevenueBreakdownDrilldownNextYear]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[RevenueBreakdown]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[RevenueBreakdownLastYear]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[RevenueBreakdownMonth]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[RevenueBreakdownNextYear]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[RevenueSummaryBreakdown]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[RevenueTargetBreakdownCCP]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[selectnotcomputed]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[TargetBreakdown]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[TargetBreakdownLastYear]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[TargetBreakdownMonth]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[TargetBreakdownNextYear]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[zzzInvoiceRunSelectionDetail]    Script Date: 18/09/2024 16:05:07 ******/
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
/****** Object:  StoredProcedure [dbo].[zzzInvoiceRunSelectionSummary]    Script Date: 18/09/2024 16:05:07 ******/
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
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 288
               Right = 461
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 3660
         Width = 2040
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SalesExecutiveEmail'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SalesExecutiveEmail'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Revenue"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 430
               Right = 365
            End
            DisplayFlags = 280
            TopColumn = 25
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceCCPTLBillableNetCosts'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceCCPTLBillableNetCosts'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r1"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 311
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v1"
            Begin Extent = 
               Top = 7
               Left = 359
               Bottom = 170
               Right = 622
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceCSMindfieldTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceCSMindfieldTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r1"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 311
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v1"
            Begin Extent = 
               Top = 7
               Left = 359
               Bottom = 170
               Right = 622
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 10
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1560
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceCSTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceCSTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r1"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 311
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v1"
            Begin Extent = 
               Top = 7
               Left = 359
               Bottom = 170
               Right = 622
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceCSTotalTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceCSTotalTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r1"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 311
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v1"
            Begin Extent = 
               Top = 7
               Left = 359
               Bottom = 170
               Right = 622
            End
            DisplayFlags = 280
            TopColumn = 2
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 10
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceMindfieldTotalTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceMindfieldTotalTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r1"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 311
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v1"
            Begin Extent = 
               Top = 7
               Left = 359
               Bottom = 170
               Right = 622
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceVoiceSRRevenue'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceVoiceSRRevenue'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r1"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 311
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v1"
            Begin Extent = 
               Top = 7
               Left = 359
               Bottom = 170
               Right = 622
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceVoiceSRTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceVoiceSRTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r1"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 311
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v1"
            Begin Extent = 
               Top = 7
               Left = 359
               Bottom = 170
               Right = 622
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 11
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceVoiceSSPNRevenue'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceVoiceSSPNRevenue'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r1"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 311
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v1"
            Begin Extent = 
               Top = 7
               Left = 359
               Bottom = 170
               Right = 622
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1896
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceVoiceSSPNTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_SourceVoiceSSPNTarget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "VET_ForecastTotal"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 234
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Tom_Forecast_Current_Campaigns'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Tom_Forecast_Current_Campaigns'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[11] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ForecastSpots"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 343
               Right = 604
            End
            DisplayFlags = 280
            TopColumn = 3
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 2160
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 2565
         Alias = 2520
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Tom_Forecast_Months'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Tom_Forecast_Months'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "RAAGENCIES (CCTRAFFICLIVE.dbo)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 265
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_AgencyCCRN'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_AgencyCCRN'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "VET_AirtimeFcst_1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 333
               Right = 302
            End
            DisplayFlags = 280
            TopColumn = 11
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_AirtimeFcst'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_AirtimeFcst'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "O"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 297
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "C"
            Begin Extent = 
               Top = 6
               Left = 335
               Bottom = 136
               Right = 562
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 10
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_CampaignDates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_CampaignDates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_CCUKNewBookingsTW'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_CCUKNewBookingsTW'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "VET_ClientCCRN (CCTRAFFICLIVE.dbo)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 119
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_ClientCCRN'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_ClientCCRN'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "VET_RevenueTY_NY"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 263
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_CreateWeeklyBookings'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_CreateWeeklyBookings'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "VET_RevenueTY_NY"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 312
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 44
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
    ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_CreateWeeklyBookingsv2'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'     Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_CreateWeeklyBookingsv2'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_CreateWeeklyBookingsv2'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "cp"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 388
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "CS"
            Begin Extent = 
               Top = 7
               Left = 436
               Bottom = 170
               Right = 716
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "P"
            Begin Extent = 
               Top = 7
               Left = 764
               Bottom = 170
               Right = 1042
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "C"
            Begin Extent = 
               Top = 7
               Left = 1090
               Bottom = 170
               Right = 1392
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "A"
            Begin Extent = 
               Top = 7
               Left = 1440
               Bottom = 170
               Right = 1742
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 5376
         Width = 2052
         Width = 2052
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Outp' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_DealIDDupesDetail'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'ut = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_DealIDDupesDetail'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_DealIDDupesDetail'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 19
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_ForecastTotal'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_ForecastTotal'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 44
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_GlobalRevenueTYNY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_GlobalRevenueTYNY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "M"
            Begin Extent = 
               Top = 7
               Left = 360
               Bottom = 170
               Right = 607
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "LR"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 312
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 11
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 4092
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_GreensRevLines_LastWeek'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_GreensRevLines_LastWeek'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "R"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 312
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "M"
            Begin Extent = 
               Top = 7
               Left = 360
               Bottom = 170
               Right = 607
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_GreensRevLines_ThisWeek'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_GreensRevLines_ThisWeek'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "R"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 352
               Right = 312
            End
            DisplayFlags = 280
            TopColumn = 32
         End
         Begin Table = "M"
            Begin Extent = 
               Top = 0
               Left = 617
               Bottom = 354
               Right = 864
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_GreensRevLines_TYNY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_GreensRevLines_TYNY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "CP"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 388
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "CS"
            Begin Extent = 
               Top = 7
               Left = 436
               Bottom = 170
               Right = 716
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "P"
            Begin Extent = 
               Top = 7
               Left = 764
               Bottom = 170
               Right = 1042
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_HSDealIDDuplicates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_HSDealIDDuplicates'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "VET_InventoryFcst"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 232
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_InventoryFcst'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_InventoryFcst'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "vet_tracker_weekly"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 312
            End
            DisplayFlags = 280
            TopColumn = 42
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 46
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_LastWeekGreens'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_LastWeekGreens'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_LastWeekGreens'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "os"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 316
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ss"
            Begin Extent = 
               Top = 7
               Left = 364
               Bottom = 170
               Right = 652
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "o"
            Begin Extent = 
               Top = 7
               Left = 700
               Bottom = 170
               Right = 1012
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 7
               Left = 1060
               Bottom = 170
               Right = 1329
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ot"
            Begin Extent = 
               Top = 175
               Left = 321
               Bottom = 338
               Right = 595
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "st"
            Begin Extent = 
               Top = 175
               Left = 643
               Bottom = 338
               Right = 927
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 175
               Left = 975
               Bottom = 338
               Right = 1283
            End
            DisplayFlags = 280
            TopColumn = 0
        ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_LiveReads'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N' End
         Begin Table = "s"
            Begin Extent = 
               Top = 175
               Left = 1331
               Bottom = 338
               Right = 1610
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sg"
            Begin Extent = 
               Top = 175
               Left = 1658
               Bottom = 338
               Right = 1903
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "se"
            Begin Extent = 
               Top = 343
               Left = 48
               Bottom = 506
               Right = 273
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "slsg"
            Begin Extent = 
               Top = 343
               Left = 321
               Bottom = 484
               Right = 547
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 17
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_LiveReads'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_LiveReads'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 44
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_LocalReconTYNY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_LocalReconTYNY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_MasterTargetTY_NY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_MasterTargetTY_NY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_NCARevenueTYNY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_NCARevenueTYNY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "VET_OffairFcst_1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 351
               Right = 312
            End
            DisplayFlags = 280
            TopColumn = 16
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_OffairFcst'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_OffairFcst'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "VET_OffPeakUsage (CCTRAFFICLIVE.dbo)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_OffPeakUsage'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_OffPeakUsage'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "o"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 360
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_OrderStartDate2Yr'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_OrderStartDate2Yr'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_Revenue3Year'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_Revenue3Year'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Revenue"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 263
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v_SalesExecutiveEmail"
            Begin Extent = 
               Top = 6
               Left = 301
               Bottom = 102
               Right = 483
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_RevenueExecEmail'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_RevenueExecEmail'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "RevenueNextYear"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 263
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v_SalesExecutiveEmail"
            Begin Extent = 
               Top = 6
               Left = 301
               Bottom = 102
               Right = 483
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_RevenueNextYearExecEmail'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_RevenueNextYearExecEmail'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "RevenuePastYears"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 263
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "v_SalesExecutiveEmail"
            Begin Extent = 
               Top = 6
               Left = 301
               Bottom = 102
               Right = 483
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_RevenuePastYearsExecEmail'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_RevenuePastYearsExecEmail'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[21] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_RevenueTY_NY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'VET_RevenueTY_NY'
GO
USE [master]
GO
ALTER DATABASE [Greens] SET  READ_WRITE 
GO
