USE [master]
GO
/****** Object:  Database [OFD]    Script Date: 02.11.2021 11:43:43 ******/
CREATE DATABASE [OFD]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'OFD', FILENAME = N'S:\SQLData\OFD.mdf' , SIZE = 12536832KB , MAXSIZE = UNLIMITED, FILEGROWTH = 524288KB )
 LOG ON 
( NAME = N'OFD_log', FILENAME = N'S:\SQLData\OFD_log.ldf' , SIZE = 393152KB , MAXSIZE = 2048GB , FILEGROWTH = 262144KB )
GO
ALTER DATABASE [OFD] SET COMPATIBILITY_LEVEL = 130
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [OFD].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [OFD] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [OFD] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [OFD] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [OFD] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [OFD] SET ARITHABORT OFF 
GO
ALTER DATABASE [OFD] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [OFD] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [OFD] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [OFD] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [OFD] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [OFD] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [OFD] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [OFD] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [OFD] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [OFD] SET  DISABLE_BROKER 
GO
ALTER DATABASE [OFD] SET AUTO_UPDATE_STATISTICS_ASYNC ON 
GO
ALTER DATABASE [OFD] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [OFD] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [OFD] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [OFD] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [OFD] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [OFD] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [OFD] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [OFD] SET  MULTI_USER 
GO
ALTER DATABASE [OFD] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [OFD] SET DB_CHAINING OFF 
GO
ALTER DATABASE [OFD] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [OFD] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [OFD] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'OFD', N'ON'
GO
ALTER DATABASE [OFD] SET QUERY_STORE = OFF
GO
USE [OFD]
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = OFF;
GO
USE [OFD]
GO
/****** Object:  User [readonly]    Script Date: 02.11.2021 11:43:43 ******/
CREATE USER [readonly] FOR LOGIN [readonly] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [ofd]    Script Date: 02.11.2021 11:43:43 ******/
CREATE USER [ofd] FOR LOGIN [ofd] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_datareader] ADD MEMBER [readonly]
GO
ALTER ROLE [db_owner] ADD MEMBER [ofd]
GO
ALTER ROLE [db_accessadmin] ADD MEMBER [ofd]
GO
ALTER ROLE [db_datareader] ADD MEMBER [ofd]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [ofd]
GO
/****** Object:  UserDefinedFunction [dbo].[ofd_get_task]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[ofd_get_task] 
(
)
RETURNS @ret table 
	(
		id int identity(1,1),
		params nvarchar(256)
	)
AS
BEGIN

	declare @dts table (rn nvarchar(64), fd date, td date)
	declare @vd table (pf date, pt date)
	declare @ss table (cuid uniqueidentifier, dt date)

	declare @i int = 33
	while @i >= 0
	begin
		insert into @vd select dateadd(day, -@i-3, getdate()), dateadd(day, -@i, getdate())
		set @i = @i - 3;
	end
	
	insert into @ss
	select cash_uid, max(open_date) as d from shifts group by cash_uid


	insert into @dts
	select 		
		kkt_reg_number,
		pf,
		pt
	from cashes as c
	full join @vd as v on v.pf is not null
	left join @ss as s on c.uid = s.cuid
	where pf > dateadd(day, -3, s.dt)


	/*

	insert into @dts
	select 
		kkt_reg_number,
		dateadd(day, -3, last_updated),
		--last_updated,
		dateadd(day, 4, last_updated)
	from cashes

	*/

	declare @iter int = 10

	while @iter > 0
	begin	
		insert into @dts
		select
			rn,
			fd,
			dateadd(day, 4, fd)
		from
			(
			select 
				rn,
				max(td) as fd
			from @dts
			where td <= getdate()
			group by
				rn
			) as t
		set @iter = @iter - 1
	end

	update @dts set td = getdate() where td > GETDATE()

	insert into @ret (params)
	select
--		'{''rn'': '''  + 
--		rn + ''', ''df'': ''' + 
--		convert(nvarchar(12), fd, 121) + ''', ''dt'': ''' +
--		convert(nvarchar(12), td, 121) + '''}'

		'rn: ' + 
		rn + ', df: ' + 
		convert(nvarchar(12), fd, 121) + ', dt: ' +
		convert(nvarchar(12), td, 121)


	from @dts
	where fd < convert(date, GETDATE())
	group by
		rn,
		fd,
		td
	order by rn, fd


	RETURN 
END
GO
/****** Object:  UserDefinedFunction [dbo].[ofd_get_task_2]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[ofd_get_task_2] 
(
	@filtrate_rn nvarchar(64)
)
RETURNS @ret table 
	(
		id int identity(1,1),
		params nvarchar(256)
	)
AS
BEGIN

	declare @dts table (rn nvarchar(64), fd date, td date)
	declare @vd table (pf date, pt date)
	declare @ss table (cuid uniqueidentifier, dt date)

	declare @i int = 33
	while @i >= 0
	begin
		insert into @vd select dateadd(day, -@i-3, getdate()), dateadd(day, -@i, getdate())
		set @i = @i - 3;
	end
	
	insert into @ss
	select cash_uid, max(open_date) as d from shifts group by cash_uid


	insert into @dts
	select 		
		kkt_reg_number,
		pf,
		pt
	from cashes as c
	full join @vd as v on v.pf is not null
	left join @ss as s on c.uid = s.cuid
	where pf > dateadd(day, -3, s.dt)


	/*

	insert into @dts
	select 
		kkt_reg_number,
		dateadd(day, -3, last_updated),
		--last_updated,
		dateadd(day, 4, last_updated)
	from cashes

	*/

	declare @iter int = 10

	while @iter > 0
	begin	
		insert into @dts
		select
			rn,
			fd,
			dateadd(day, 4, fd)
		from
			(
			select 
				rn,
				max(td) as fd
			from @dts
			where td <= getdate()
			group by
				rn
			) as t
		set @iter = @iter - 1
	end

	update @dts set td = getdate() where td > GETDATE()

	insert into @ret (params)
	select
--		'{''rn'': '''  + 
--		rn + ''', ''df'': ''' + 
--		convert(nvarchar(12), fd, 121) + ''', ''dt'': ''' +
--		convert(nvarchar(12), td, 121) + '''}'

		'rn: ' + 
		rn + ', df: ' + 
		convert(nvarchar(12), fd, 121) + ', dt: ' +
		convert(nvarchar(12), td, 121)


	from @dts
	where 
		fd < convert(date, GETDATE())
		and rn in
		(
		'0004497119006617',
'0004497119006617',
'0005668170058490',
'0005690997004621',
'0005677534006844',
'0005667708043608',
'0000564666059219',
'0000564666059219',
'0000564666059219',
'0000564666059219',
'0000564666059219',
'0000564666059219',
'0000564666059219',
'0000564666059219',
'0005671944017497',
'0005283923043310',
'0005284476015755',
'0005292328062952',
'0005732978042572'
		)
	group by
		rn,
		fd,
		td
	order by rn, fd


	RETURN 
END
GO
/****** Object:  Table [dbo].[shops]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[shops](
	[uid] [uniqueidentifier] NOT NULL,
	[shop_id] [bigint] NOT NULL,
	[shop_name] [nvarchar](256) NOT NULL,
	[shop_guid] [uniqueidentifier] NOT NULL,
 CONSTRAINT [pk_shops] PRIMARY KEY CLUSTERED 
(
	[uid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[cashes]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cashes](
	[uid] [uniqueidentifier] NOT NULL,
	[shop_uid] [uniqueidentifier] NOT NULL,
	[load_dts] [datetime] NOT NULL,
	[kkt_number] [nvarchar](32) NOT NULL,
	[kkt_reg_number] [nvarchar](32) NOT NULL,
	[kkt_fiscal_number] [nvarchar](32) NOT NULL,
	[cash_name] [nvarchar](512) NOT NULL,
	[last_updated] [date] NOT NULL,
 CONSTRAINT [PK_cashes] PRIMARY KEY CLUSTERED 
(
	[uid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[shifts]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[shifts](
	[uid] [uniqueidentifier] NOT NULL,
	[cash_uid] [uniqueidentifier] NOT NULL,
	[shift_number] [bigint] NOT NULL,
	[fiscal_number] [bigint] NOT NULL,
	[open_date] [date] NOT NULL,
	[close_date] [date] NOT NULL,
	[total] [money] NOT NULL,
	[tax_total] [money] NOT NULL,
	[tax_none] [money] NOT NULL,
	[tax_0] [money] NOT NULL,
	[tax_10] [money] NOT NULL,
	[tax_18] [money] NOT NULL,
	[tax_20] [money] NOT NULL,
	[ecash_total] [money] NOT NULL,
	[cash_total] [money] NOT NULL,
	[return_ecash] [money] NOT NULL,
	[return_cash] [money] NOT NULL,
	[cheque_id] [bigint] NOT NULL,
 CONSTRAINT [PK_sifts] PRIMARY KEY CLUSTERED 
(
	[uid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[get_ofdshifts_v2]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[get_ofdshifts_v2] 
(	
	@fd date,
	@td date
)
RETURNS TABLE 
AS
RETURN 
(
	select
		t.shop_name as [Магазин],
		'' as [КПП],
		c.kkt_reg_number as [ККТ],
		c.kkt_fiscal_number as [ФН],
		s.fiscal_number as [ФНД],
		s.open_date as [Дата],
		s.shift_number as [Смена],
		s.total as [Итого],
		s.tax_total as [Итого НДС],
		s.tax_none as [В т.ч. Без НДС],
		s.tax_0 as [В т.ч. НДС  0%],
		s.tax_10 as [В т.ч. НДС 10%],
		s.tax_18 as [В т.ч. НДС 18%],
		s.tax_20 as [В т.ч. НДС 20%],
		s.ecash_total as [Эл],
		s.cash_total as [Нл],
		s.return_ecash as [В т.ч. ВЭл],
		s.return_cash as [В т.ч. ВНл],
		t.shop_id as [Идентификатор ТТ]
	from [shifts] as s
	left join [cashes] as c with (nolock) on s.cash_uid = c.uid
	left join [shops] as t on c.shop_uid = t.uid	
	where 
		s.open_date between @fd and @td

)
GO
/****** Object:  Table [dbo].[checks]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[checks](
	[uid] [uniqueidentifier] NOT NULL,
	[cash_uid] [uniqueidentifier] NOT NULL,
	[shift_number] [bigint] NOT NULL,
	[operation_type] [int] NOT NULL,
	[document_type] [int] NOT NULL,
	[cheque_date] [datetime] NOT NULL,
	[cheque_number] [bigint] NOT NULL,
	[cheque_id] [bigint] NOT NULL,
	[cheque_fnum] [bigint] NOT NULL,
	[cheque_fstamp] [bigint] NOT NULL,
	[tax_type_id] [int] NOT NULL,
	[tax_none] [money] NOT NULL,
	[tax_0] [money] NOT NULL,
	[tax_10] [money] NOT NULL,
	[tax_18] [money] NOT NULL,
	[tax_20] [money] NOT NULL,
	[tax_total] [money] NOT NULL,
	[cash_total] [money] NOT NULL,
	[ecash_total] [money] NOT NULL,
	[total] [money] NOT NULL,
	[hash] [bigint] NOT NULL,
 CONSTRAINT [PK_checks] PRIMARY KEY CLUSTERED 
(
	[uid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[operationtypes]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[operationtypes](
	[operation_id] [int] NOT NULL,
	[value] [nvarchar](128) NOT NULL,
 CONSTRAINT [PK_ofd_operationtypes] PRIMARY KEY CLUSTERED 
(
	[operation_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[doctypes]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[doctypes](
	[doc_type] [int] NOT NULL,
	[value] [nvarchar](128) NOT NULL,
 CONSTRAINT [PK_ofd_doctypes] PRIMARY KEY CLUSTERED 
(
	[doc_type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[get_ofdshiftdetailed]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[get_ofdshiftdetailed] 
(	
	@cashboxnum nvarchar(64),
	@fiscalnum nvarchar(64),
	@shift int
)
RETURNS TABLE 
AS
RETURN 
(

	select
		s.shop_name as Магазин,
		'' as КПП,
		ch.kkt_reg_number as ККТ,
		ch.kkt_fiscal_number as ФН,
		c.shift_number as Смена,
		d.value as Документ,
		o.value as Операция,
		c.cheque_fstamp as [Номер Чека],
		c.operation_type as [Вид Платежа],
		convert(date, c.cheque_date) as Дата,
		convert(nvarchar(8), convert(time, c.cheque_date)) as Время,
		c.total as Итого,
		c.tax_total as [Итого НДС],
		c.tax_none as [В т.ч. Без НДС],
		c.tax_0 as [В т.ч. НДС  0%],
		c.tax_10 as [В т.ч. НДС 10%],
		c.tax_18 as [В т.ч. НДС 18%],
		c.tax_20 as [В т.ч. НДС 20%],
		c.ecash_total as [Безналичные],
		c.cash_total as [Наличные],
		s.shop_id as [Идентификатор ТТ]	
	from [checks] as c
	left join [operationtypes] as o on o.operation_id = c.operation_type
	left join [doctypes] as d on d.doc_type = c.document_type
	left join [cashes] as ch with (nolock) on c.cash_uid = ch.uid
	left join [shops] as s on ch.shop_uid = s.uid
	where 
		kkt_reg_number = @cashboxnum
		and kkt_fiscal_number = @fiscalnum
		and c.shift_number = @shift
)
GO
/****** Object:  Table [dbo].[import]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[import](
	[uuid] [uniqueidentifier] NOT NULL,
	[dd] [date] NOT NULL,
	[dt] [time](7) NOT NULL,
	[packet_name] [nvarchar](256) NOT NULL,
	[packet_data] [varbinary](max) NOT NULL,
	[processed] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [nci_cashes_num_rnum_fnum]    Script Date: 02.11.2021 11:43:43 ******/
CREATE NONCLUSTERED INDEX [nci_cashes_num_rnum_fnum] ON [dbo].[cashes]
(
	[kkt_number] ASC,
	[kkt_reg_number] ASC,
	[kkt_fiscal_number] ASC,
	[cash_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_checks_hash]    Script Date: 02.11.2021 11:43:43 ******/
CREATE NONCLUSTERED INDEX [ix_checks_hash] ON [dbo].[checks]
(
	[hash] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_checks_key]    Script Date: 02.11.2021 11:43:43 ******/
CREATE NONCLUSTERED INDEX [ix_checks_key] ON [dbo].[checks]
(
	[cash_uid] ASC,
	[shift_number] ASC,
	[cheque_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_checks_link]    Script Date: 02.11.2021 11:43:43 ******/
CREATE NONCLUSTERED INDEX [ix_checks_link] ON [dbo].[checks]
(
	[cheque_id] ASC,
	[cheque_fstamp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_sifts]    Script Date: 02.11.2021 11:43:43 ******/
CREATE NONCLUSTERED INDEX [IX_sifts] ON [dbo].[shifts]
(
	[cash_uid] ASC,
	[shift_number] ASC,
	[cheque_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cashes] ADD  CONSTRAINT [DF_cashes_uid]  DEFAULT (newid()) FOR [uid]
GO
ALTER TABLE [dbo].[cashes] ADD  CONSTRAINT [DF_cashes_load_dts]  DEFAULT (getdate()) FOR [load_dts]
GO
ALTER TABLE [dbo].[cashes] ADD  CONSTRAINT [DF_cashes_last_updated]  DEFAULT (getdate()-(100)) FOR [last_updated]
GO
ALTER TABLE [dbo].[checks] ADD  CONSTRAINT [DF_checks_uid]  DEFAULT (newid()) FOR [uid]
GO
ALTER TABLE [dbo].[import] ADD  DEFAULT (newid()) FOR [uuid]
GO
ALTER TABLE [dbo].[import] ADD  CONSTRAINT [DF_Table_1_dt]  DEFAULT (getdate()) FOR [dd]
GO
ALTER TABLE [dbo].[import] ADD  CONSTRAINT [DF_Table_1_dts]  DEFAULT (getdate()) FOR [dt]
GO
ALTER TABLE [dbo].[import] ADD  CONSTRAINT [DF_import_packet_name]  DEFAULT ('noname') FOR [packet_name]
GO
ALTER TABLE [dbo].[import] ADD  CONSTRAINT [DF_import_packet_data]  DEFAULT (0x00) FOR [packet_data]
GO
ALTER TABLE [dbo].[import] ADD  CONSTRAINT [DF_import_processed]  DEFAULT ((0)) FOR [processed]
GO
ALTER TABLE [dbo].[shifts] ADD  DEFAULT (newid()) FOR [uid]
GO
ALTER TABLE [dbo].[shops] ADD  DEFAULT (newid()) FOR [uid]
GO
ALTER TABLE [dbo].[cashes]  WITH CHECK ADD  CONSTRAINT [FK_cashes_shops] FOREIGN KEY([shop_uid])
REFERENCES [dbo].[shops] ([uid])
GO
ALTER TABLE [dbo].[cashes] CHECK CONSTRAINT [FK_cashes_shops]
GO
ALTER TABLE [dbo].[checks]  WITH CHECK ADD  CONSTRAINT [FK_checks_cashes] FOREIGN KEY([cash_uid])
REFERENCES [dbo].[cashes] ([uid])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[checks] CHECK CONSTRAINT [FK_checks_cashes]
GO
ALTER TABLE [dbo].[shifts]  WITH CHECK ADD  CONSTRAINT [fk_sifts_cashes] FOREIGN KEY([cash_uid])
REFERENCES [dbo].[cashes] ([uid])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[shifts] CHECK CONSTRAINT [fk_sifts_cashes]
GO
/****** Object:  StoredProcedure [dbo].[ofd_process_import]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ofd_process_import]
	@packet_name nvarchar(128),
	@packet_data xml = null
AS
BEGIN
	SET NOCOUNT ON;
	
	--declare @packet_name nvarchar(128) = 'import_cashdata'
	declare @vv table (id int identity(1,1), uuid uniqueidentifier, packet_data xml)
	declare @xml xml
	declare @h int;

	if @packet_data is null
	begin
		insert into @vv (uuid, packet_data)
		select top 1
			uuid, 
			convert(xml, packet_data) as packet_data
		from [import] 
		where 
			processed = 0
			and packet_name = @packet_name
		order by dd, dt

		set @xml = (select packet_data from @vv)
	end else
	begin
		set @xml = @packet_data
	end
	
	execute sp_xml_preparedocument @h OUTPUT, @xml, '';

	if object_id('tempdb..#tmp_ofd_cashlist') is not null drop table #tmp_ofd_cashlist
	if object_id('tempdb..#cash_data_temp') is not null drop table #cash_data_temp
	if object_id('tempdb..#tmp_cash_data_all') is not null drop table #tmp_cash_data_all
	if object_id('tempdb..#tmp_ofd_cashlist_detailed') is not null drop table #tmp_ofd_cashlist_detailed

	select *
	into #tmp_ofd_cashlist
	from openxml(@h, '/cashes/row')
	with
		(
			[main_branch] bigint '@main_branch',
			[main_branch_name] nvarchar(256) '@main_branch_name',
			[child_branch] bigint '@child_branch',
			[child_branch_name] nvarchar(256) '@child_branch_name',
			[kkt_number] nvarchar(256) '@kkt_number',
			[kkt_reg_number] nvarchar(256) '@kkt_reg_number',
			[kkt_fiscal_number] nvarchar(256) '@kkt_fiscal_number',
			[kkt_name] nvarchar(256) '@kkt_name',
			[updated] date '@updated'

		)

	--Запишем магазины.
	insert into [shops]
	select x.* from 
	(
	select
		newid() as uuid,
		child_branch as shop_id,
		[child_branch_name] as shop_name,
		newid() as shop_guid
	from #tmp_ofd_cashlist
	group by
		child_branch,
		[child_branch_name]
	) as x
	left join [shops] as s with (nolock) on x.shop_id = s.shop_id
	where s.shop_id is null


	--Пишем ККТ.
	select
		newid() as uid,
		s.uid as shop_uid,
		isnull(c.load_dts, getdate()) as load_dts,
		x.kkt_number,
		x.kkt_reg_number,
		x.kkt_fiscal_number,
		x.cash_name,
		isnull(c.last_updated, x.last_updated) as last_updated
	into #tmp_ofd_cashlist_detailed
	from
	(
	select
		newid() as uid,
		getdate() as load_dts,
		kkt_number,
		kkt_reg_number,
		kkt_fiscal_number,
		kkt_name as cash_name,
		updated as last_updated,
		child_branch
	from  #tmp_ofd_cashlist
	) as x
	left join cashes as c with (nolock) on c.kkt_number = x.kkt_number and c.kkt_reg_number = x.kkt_reg_number and c.kkt_fiscal_number = x.kkt_fiscal_number and c.cash_name = x.cash_name
	left join shops as s with (nolock) on x.child_branch = s.shop_id

	create nonclustered index nci_tmp_ofd_cashlist_keys on #tmp_ofd_cashlist_detailed (shop_uid, kkt_number, kkt_reg_number, kkt_fiscal_number)

	--Срез всех касс в момент загрузки.
	insert into cashes
	select
		t1.*
	from #tmp_ofd_cashlist_detailed as t1 with (nolock)
	left join [cashes] as c with (nolock) on t1.shop_uid = c.shop_uid and t1.kkt_number = c.kkt_number and t1.kkt_reg_number = c.kkt_reg_number and t1.kkt_fiscal_number = c.kkt_fiscal_number
	where c.uid is null

	select
		rqId,
		taxationTypeId,
		kktRegId as kkt_reg_number,
		fnSn as kkt_fiscal_number,
		kktName as cash_name,
		--operator as cashier,
		shiftNumber as shift_number,
		reqDocDate as cheque_date,
		requestNumber as cheque_number,
		fiscalDocumentNumber as fiscal_cheque_num,
		operationTypeId as operation_type,		
		docFP,		
		docTypeId as document_type,
		isnull(ndsn, 0) as tax_none,
		isnull(nds0, 0) as tax_0,
		isnull(nds10, 0) as tax_10,
		case 
			when reqDocDate < '20200101' then isnull(nds18, 0)
			else 0
		end as tax_18,
		case 
			when reqDocDate >= '20200101' then isnull(nds18, 0)
			else 0
		end as tax_20,
		isnull(cashTotalSum, 0) as cash_total,
		isnull(eCashTotalSum, 0) as ecash_total,
		isnull(totalSum, 0) as total
	into #cash_data_temp
	from openxml(@h, '/root/row')
	with
		(
			rqId bigint '@rqId',
			taxationTypeId int '@taxationTypeId',
			kktRegId nvarchar(64) '@kktRegId',
			fnSn nvarchar(64) '@fnSn',
			kktName nvarchar(256) '@kktName',
			--operator nvarchar(128) '@operator',
			shiftNumber bigint '@shiftNumber',
			requestNumber bigint '@requestNumber',
			operationTypeId int '@operationTypeId',
			reqDocDate datetime,
			docFp nvarchar(64) '@docFp',
			fiscalDocumentNumber bigint '@fiscalDocumentNumber',
			docTypeId int '@docTypeId',
			ndsn int '@ndsNo',
			nds0 int '@nds0',
			nds10 int '@nds10',
			nds18 int '@nds18',
			nds20 int '@nds20',
			cashTotalSum int '@cashTotalSum',
			eCashTotalSum int '@eCashTotalSum',
			totalSum int '@totalSum'			
		) as x
		order by x.rqId

	create index nci_cash_data_temp_key on #cash_data_temp (kkt_reg_number, kkt_fiscal_number, cash_name)

	select
		cn.uid as cash_uid,
		shift_number,
		--cashier,
		operation_type,
		document_type,
		cheque_date,
		cheque_number,
		cq.rqId as cheque_id,
		fiscal_cheque_num as cheque_fnum,
		docFP as cheque_fstamp,
		taxationTypeId as tax_type_id,
		convert(money, tax_none) /100 as tax_none,
		convert(money, tax_0) / 100 as tax_0,
		convert(money, tax_10) / 100 as tax_10,
		convert(money, tax_18) / 100 as tax_18,
		convert(money, tax_20) / 100 as tax_20,
		convert(money, tax_none + tax_0 + tax_10 + tax_18 + tax_20) / 100 as tax_total,
		convert(money, cash_total) / 100 as cash_total,
		convert(money, ecash_total) / 100 as ecash_total,
		convert(money, total) / 100 as total
	into #tmp_cash_data_all
	from #cash_data_temp as cq with (nolock)
	left join [cashes] as cn with (nolock) on cq.kkt_reg_number = cn.kkt_reg_number and cq.kkt_fiscal_number = cn.kkt_fiscal_number and cq.cash_name = cn.cash_name
	--Только известные нам кассы.
	where cn.uid is not null

	create unique clustered index uci_key_tmp_cash_data_all on #tmp_cash_data_all (cash_uid, shift_number, cheque_id, cheque_fnum)

	insert into [checks]
	select 
		newid(),
		t2.*
	from (
	select 
		t1.*, 
		BINARY_CHECKSUM(cash_uid, shift_number, cheque_number, cheque_fnum, cheque_id) as hash
	from #tmp_cash_data_all as t1 with (nolock)
	) as t2
	left join [checks] as c with (nolock) on t2.cash_uid = c.cash_uid and t2.hash = c.hash and t2.cheque_fstamp = c.cheque_fstamp and t2.cheque_id = c.cheque_id
	where c.uid is null

	--Обновим временную метку.
	update c
		set c.last_updated = t1.last_updated
	from
	(
		select 
			kkt_reg_number,
			dateadd(day, -1, max(cheque_date)) as last_updated
		from #cash_data_temp
		group by 
			kkt_reg_number
	) as t1
	left join cashes as c with (nolock) on c.kkt_reg_number = t1.kkt_reg_number

	update [import] set processed = 1 where uuid = (select uuid from @vv)
	delete from import where dd < getdate()-7



END
GO
/****** Object:  StoredProcedure [dbo].[ofd_process_shifts]    Script Date: 02.11.2021 11:43:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ofd_process_shifts]
AS
BEGIN
	SET NOCOUNT ON;

	if object_id('tempdb..#shift_list_prepare') is not null drop table #shift_list_prepare
	if object_id('tempdb..#shift_list_counts') is not null drop table #shift_list_counts
	if object_id('tempdb..#shift_list_opened') is not null drop table #shift_list_opened
	if object_id('tempdb..#shift_list_closed') is not null drop table #shift_list_closed
	if object_id('tempdb..#shift_list') is not null drop table #shift_list

	select
		s.*
	into #shift_list_prepare
	from cashes as c with (nolock)
	left join checks as s with (nolock) on c.uid = s.cash_uid and s.cheque_date >= dateadd(day, -14, c.last_updated)

	create index ix_tmp_shift_list_prepare_cid on #shift_list_prepare (cash_uid, document_type, shift_number, cheque_id)

	select
		cash_uid,
		shift_number,
		sum(case when operation_type in (1,4) then tax_none else -tax_none end) as tax_none,
		sum(case when operation_type in (1,4) then tax_0 else -tax_0 end) as tax_0,
		sum(case when operation_type in (1,4) then tax_10 else -tax_10 end) as tax_10,
		sum(case when operation_type in (1,4) then tax_18 else -tax_18 end) as tax_18,
		sum(case when operation_type in (1,4) then tax_20 else -tax_20 end) as tax_20,
		sum(case when operation_type in (1,4) then tax_total else -tax_total end) as tax_total,
		sum(case when operation_type in (1,4) then cash_total else -cash_total end) as cash_total,
		sum(case when operation_type in (1,4) then ecash_total else -ecash_total end) as ecash_total,
		sum(case when operation_type in (1,4) then total else -total end) as total,
		sum(case when operation_type = 2 and document_type = 3 then ecash_total else 0 end) as ret_ec,
		sum(case when operation_type = 2 and document_type = 3 then cash_total else 0 end) as ret_cc,
		min(cheque_fnum) - 1 as cheque_fnum_first,
		max(cheque_fnum) + 1 as cheque_fnum_last	
	into #shift_list_counts
	from #shift_list_prepare
	where document_type in (3,31,41)
	group by
		cash_uid,
		shift_number

	create index ix_001 on #shift_list_counts (cash_uid, shift_number, cheque_fnum_first, cheque_fnum_last)


	select
		o.cash_uid,
		o.shift_number,
		o.cheque_fnum,
		isnull(c.cheque_fnum_last, o.cheque_fnum + 1) as cheque_fnum_last,
		convert(date, o.cheque_date) as open_date,
		isnull(c.tax_none, 0) as tax_none,
		isnull(c.tax_0, 0) as tax_0,
		isnull(c.tax_10, 0) as tax_10,
		isnull(c.tax_18, 0) as tax_18,
		isnull(c.tax_20, 0) as tax_20,
		isnull(c.tax_total, 0) as tax_total,
		isnull(c.cash_total, 0) as cash_total,
		isnull(c.ecash_total, 0) as ecash_total,
		isnull(c.total, 0) as total,
		isnull(c.ret_ec, 0) as ret_ec,
		isnull(c.ret_cc, 0) as ret_cc
	into #shift_list_opened
	from #shift_list_prepare as o
	left join #shift_list_counts as c on o.cash_uid = c.cash_uid and o.shift_number = c.shift_number and o.cheque_fnum = c.cheque_fnum_first
	where o.document_type = 2
	group by
		o.cash_uid,
		o.shift_number,
		o.cheque_fnum,
		convert(date, o.cheque_date),
		c.tax_none,
		c.tax_0,
		c.tax_10,
		c.tax_18,
		c.tax_20,
		c.tax_total,
		c.cash_total,
		c.ecash_total,
		c.total,
		c.cheque_fnum_last,
		c.ret_ec,
		c.ret_cc

	create index ix_001 on #shift_list_opened (cash_uid, shift_number, cheque_fnum_last)

	select
		cash_uid,
		shift_number,
		cheque_fnum,
		cheque_id,
		convert(date, cheque_date) as close_date
	into #shift_list_closed
	from #shift_list_prepare
	where document_type = 5
	group by
		cash_uid,
		shift_number,
		cheque_fnum,
		cheque_id,
		convert(date, cheque_date)


	create index ix_001 on #shift_list_closed (cash_uid, shift_number, cheque_fnum)


	select 
		o.cash_uid,
		o.shift_number,
		c.cheque_fnum as cheque_fnum,
		o.open_date,
		c.close_date,
		o.total,
		o.tax_total,
		o.tax_none,
		o.tax_0,
		o.tax_10,
		o.tax_18,
		o.tax_20,
		o.ecash_total,
		o.cash_total,
		o.ret_ec,
		o.ret_cc,
		c.cheque_id
	into #shift_list
	from #shift_list_opened as o
	left join #shift_list_closed as c on o.cash_uid = c.cash_uid and o.shift_number = c.shift_number and o.cheque_fnum_last = c.cheque_fnum
	where c.cheque_id is not null

	create unique clustered index ix_001 on #shift_list (cash_uid, shift_number, cheque_id)

	if object_id('tempdb..#shift_list_prepare') is not null drop table #shift_list_prepare
	if object_id('tempdb..#shift_list_counts') is not null drop table #shift_list_counts
	if object_id('tempdb..#shift_list_opened') is not null drop table #shift_list_opened
	if object_id('tempdb..#shift_list_closed') is not null drop table #shift_list_closed

	insert into [shifts]
	select
		newid(),
		t.*
	from #shift_list as t
	left join shifts as s with (nolock) on t.cash_uid = s.cash_uid and t.shift_number = s.shift_number and t.cheque_id = s.cheque_id
	where s.uid is null



END
GO
USE [master]
GO
ALTER DATABASE [OFD] SET  READ_WRITE 
GO
