/****** Object:  UserDefinedFunction [dbo].[fn_RevenueSummaryWeekSplit]    Script Date: 18/09/2024 16:20:10 ******/
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
/****** Object:  UserDefinedFunction [dbo].[fn_Split]    Script Date: 18/09/2024 16:20:10 ******/
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
