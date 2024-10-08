/****** Object:  Table [dbo].[BenchmarkRatesforCPT]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[briefs]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ForecastSpots]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ForecastTrackerMonthEnd]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ForecastTrackerRevenue]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ForecastTrackerWeeklyForecast]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[gomoRevenue]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ReferenceGPStationMapping]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ReferenceNCASalesExecutives]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ReferenceNominalCodeMapping]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ReferenceRevenueSummaryTargetPercentage]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ReferenceSalesGroupBreakdown]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ReferenceSalesGroupBreakdownMonthly]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ReferenceSalesGroupBreakdownSFT]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ReferenceSourceFilters]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[ReferenceStreamMapping]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[Revenue]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[RevenueNextYear]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[RevenueNextYearStaging]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[RevenuePastYears]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[RevenueStaging]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[vet_tracker_weekly]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[xxRevenue]    Script Date: 18/09/2024 16:18:43 ******/
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
/****** Object:  Table [dbo].[xxRevenueStaging]    Script Date: 18/09/2024 16:18:43 ******/
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
