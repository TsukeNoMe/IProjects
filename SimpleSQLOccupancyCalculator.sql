CREATE TYPE KeyValue AS TABLE (
	Id int identity(1,1)
	,ColumnName VARCHAR(100)
	,ColumnValue NVARCHAR(MAX)
	)



CREATE PROCEDURE CalculateOccupancy @DatabaseName VARCHAR(100)
	,@TableName VARCHAR(100)
	,@SearchString KeyValue READONLY
AS


DECLARE @SQLString NVARCHAR(MAX)

IF @DatabaseName IS NOT NULL
	AND LEN(@DatabaseName) > 0
BEGIN
	SET @SQLString = '
	Use ' + @DatabaseName + ' ;'
END

IF (Select Count(*) From @SearchString) = 0
BEGIN

	SET @SQLString += 'exec sp_spaceused ''' + @TableName + ''''
	EXEC(@SQLString)
	RETURN;

END


IF @TableName IS NOT NULL
	AND LEN(@TableName) > 0 
BEGIN
	BEGIN TRY
	
		SET @SQLString += ' Select  * into ##OccupancyCalculation from '
	
		SET @SQLString += @TableName

		IF (
				SELECT count(*)
				FROM @SearchString
				) > 0
		BEGIN
			SET @SQLString += ' where '

			DECLARE @Loop int = 1, @MaxValue int = (Select count(*) From @SearchString)
			
			WHILE (@Loop <= @MaxValue)
			BEGIN
			
				
				DECLARE @Column VARCHAR(100)
					,@Value NVARCHAR(MAX)
				
				Select @Column = ColumnName, @Value = ColumnValue From @SearchString
				where Id = @Loop
				
				IF(@Loop = 1)
				BEGIN
					
					SET @SQLString += @Column + ' = ''' + @Value + ''' '
				
				END
				ELSE
				BEGIN
				
					SET @SQLString += ' and ' + @Column + ' = ''' + @Value + ''' '
				
				END
			
				SET @Loop += 1
			
			END
			

			
		END

		PRINT @SQLString

		EXEC (@SQLString)

		DECLARE @SizeCalculation NVARCHAR(MAX) = 'DECLARE @SpaceSTAT TABLE(
		name varchar(100),
		rows int,
		reserved varchar(250),
		data varchar(250),
		index_size varchar(250),
		unused varchar(250)
		) 

		use tempdb
		insert into @SpaceSTAT
		exec sp_spaceused ##OccupancyCalculation

		Select * From @SpaceSTAT
		'

		EXEC (@SizeCalculation)

		DROP TABLE ##OccupancyCalculation
	END TRY

	BEGIN CATCH
		SELECT ERROR_NUMBER() AS ErrorNumber
			,ERROR_SEVERITY() AS ErrorSeverity
			,ERROR_STATE() AS ErrorState
			,ERROR_PROCEDURE() AS ErrorProcedure
			,ERROR_LINE() AS ErrorLine
			,ERROR_MESSAGE() AS ErrorMessage;
	END CATCH
END
ELSE
BEGIN
	PRINT 'Empty or null table name';

	RETURN;
END