/****** Object:  View [dbo].[v_RevenueLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutiveLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceSalesExecutiveLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutiveClientLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SalesExecutiveEmail]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_RevenueExecEmail]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_RevenuePastYearsExecEmail]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutiveClient]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceExecutiveClient]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceExecutiveClientLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalAssistedWins]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceNCARevenueTarget]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_RevenueLastYearPlus1]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutiveClientLastYearPlus1]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceExecutiveClientLastYearPlus1]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceExecutiveGlobalAssistedWins]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceExecutiveMasterTarget]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_CurrentExecs]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_AgencyCCRN]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_ClientCCRN]    Script Date: 18/09/2024 16:19:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_ClientCCRN]
AS
SELECT        CLIENTNAME, CLIENTCRN, CCRN
FROM            CCTRAFFICLIVE.dbo.VET_ClientCCRN
GO
/****** Object:  View [dbo].[VET_3MthRevenue]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_RevenueLastYearPlus2]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutiveClientLastYearPlus2]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceExecutiveClientLastYearPlus2]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCCPTLBillableNetCosts]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceVoiceSRRevenue]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceMasterTarget]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceVoiceSRTarget]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_AirtimeFcst]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_OffairFcst]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_ForecastTotal]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCCPTL]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCCPTLLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCCPTLLastThisYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCCPTLNoAWLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCCPTLNoAW]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCCPTLNoAWLastThisYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCCPTLNoAWNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCCPTLNoAWThisNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCCPTLNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCCPTLThisNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalBillableWithAW]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalBillableWithAWLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalBillableWithAWLastThisYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalBillableWithAWNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalBillableWithAWThisNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceMasterTargetNoAW]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceMasterTargetNoAWNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceMasterTargetNoAWThisNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceMasterTargetNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceMasterTargetThisNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_RevenueSummaryBreakdown]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_Tom_Forecast_Current_Campaigns]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceAssistedWinsLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_RevenueTY_NY]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_GreensRevLines_TYNY]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_LastWeekGreens]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_GreensRevLines_LastWeek]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCSTarget]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCSTotalTarget]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_MasterTargetTY_NY]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceMasterTargetLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_GreensRevLines_ThisWeek]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceNCARevenueTargetLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceNCARevenueTargetNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceNCASalesExecutiveLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_CreateWeeklyBookings]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutiveNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceSalesExecutiveNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_RevenueNextYearExecEmail]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_Revenue3Year]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceCSMindfieldTarget]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceMindfieldTotalTarget]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_AccountsRev2YrStartDates]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceAssistedWins]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceAssistedWinsNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceAssistedWinsThisNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalBillable]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalBillableNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalBillableThisNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_CreateWeeklyBookingsv2]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_NCARevenueTYNY]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceVoiceSSPNTarget]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceVoiceSSPNRevenue]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalAssistedWinsExecutive]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceSalesExecutive]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceGlobalBillableLastYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_Ema_SourceCCPTL]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceExecutiveCCPTL]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_RevenueTargetNCAAssistedWins]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceExecutiveAssistedWins]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceExecutiveGlobalBillable]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceForecastTracker]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceNCASalesExecutive]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_SourceNCASalesExecutiveNextYear]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[v_Tom_Forecast_Months]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_CampaignDates]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_CCUKNewBookingsTW]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_DealIDDupesDetail]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_GlobalRevenueTYNY]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_HSDealIDDuplicates]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_InventoryFcst]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_LiveReads]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_LocalReconTYNY]    Script Date: 18/09/2024 16:19:07 ******/
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
/****** Object:  View [dbo].[VET_OffPeakUsage]    Script Date: 18/09/2024 16:19:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VET_OffPeakUsage]
AS
SELECT        ORDERID, SalesExec, Client, Station, OrderType, Created, StartDate, EndDate, TotalSpots, OffpeakSpots, Percentage
FROM            CCTRAFFICLIVE.dbo.VET_OffPeakUsage
GO
/****** Object:  View [dbo].[VET_OrderStartDate2Yr]    Script Date: 18/09/2024 16:19:07 ******/
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
