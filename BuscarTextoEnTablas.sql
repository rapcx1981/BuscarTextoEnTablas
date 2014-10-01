CREATE PROC BuscarTextoEnTablas
(
@TMP NVARCHAR(MAX),
@Print BIT=0
)
AS
/*
Autor:		Rodrigo Anael Perez Castro | rapcx1981@gmail.com  
Creado:		30/12/2013 | Ultima Actualizacion:N/A

SINTAXIS:	

-Si se buscara el texto en todas las tablas:
				BuscarTextoEnTablas '<Texto a Buscar>'	Ej: BuscarTextoEnTablas 'A Bike Store',1 
-Si se buscara el texto en un grupo especifico de tablas:
				BuscarTextoEnTablas '<Texto a Buscar> IN <Tabla 1>,<Tabla 2>, <Tabla N>' Ej: BuscarTextoEnTablas 'A Bike Store IN dimreseller,dimaccount,dimdate' 
				
-Opcionalmente se puede especificar 1 despues del texto para indicar si se requiere mostrar el query generado en la pestaña de "Mensajes". Si no se 
 indica nada automaticamente asume que no se requiere.	 
								
NOTAS:		

-Basado en la idea y trabajo de Narayana Vyas Kondreddi [SearchAllTables/http://vyaskn.tripod.com/search_all_columns_in_all_tables.htm]			
*/
BEGIN
--VARIABLES DE ENTORNO--------------------------------------------------------
DECLARE @Query NVARCHAR(MAX)=NULL

SET @Query=N'
--VARIABLES DE ENTORNO--------------------------------------------------------
DECLARE @Buscar VARCHAR(MAX)=NULL
DECLARE @Ciclos TINYINT=0'
--REFERENCIAS: http://sqlservercodebook.blogspot.mx/2008/03/check-if-temporary-table-exists.html
SET @Query=@Query+'
IF OBJECT_ID(''tempdb..#Results'') IS NOT NULL  
	BEGIN
		DROP TABLE #Results
	END

CREATE TABLE #Results (ColumnName NVARCHAR(370), ColumnValue NVARCHAR(3630))

SET NOCOUNT ON'

IF ((SELECT CHARINDEX('IN',@TMP))>0)
	BEGIN 
	SET @Query=@Query+'
		SET @Buscar=QUOTENAME(''%'' +(SELECT LTRIM(RTRIM(SUBSTRING('''+@TMP+''',0,(CHARINDEX(''IN'','''+@TMP+''')-1)))))+ ''%'','''''''')'
		--SEPARACION DE CADENA PARA FORMAR TABLA---------------------------------------------------------
		--BASADO EN LA FUNCION: http://emmersonmiranda-net.blogspot.mx/2008/08/generando-mltiples-filas-de-un-string.html
		--Writen By: Emmerson Miranda
	SET @Query=@Query+
	   'DECLARE @Tablas TABLE (Tabla NVARCHAR(75),N TINYINT IDENTITY)
		DECLARE @Array VARCHAR(MAX)=(SELECT LTRIM(RTRIM((SELECT SUBSTRING('''+@TMP+''',(SELECT CHARINDEX(''IN'','''+@TMP+''')+2),LEN('''+@TMP+'''))))))
		DECLARE @SeparatorPosition INT=0
		DECLARE @ArrayValue VARCHAR(MAX)=NULL

		SET @Array = @Array + '',''

		WHILE PATINDEX(''%'' + '','' + ''%'' , @Array) <> 0
		BEGIN
			SET @SeparatorPosition = PATINDEX(''%'' + '','' + ''%'' , @Array)
			SET @ArrayValue = SUBSTRING(@Array, 0, @SeparatorPosition)
			SET @Array = STUFF(@Array, 1, @SeparatorPosition, '''')
			INSERT INTO @Tablas SELECT ''[dbo].[''+@ArrayValue+'']'' AS Tabla
		END
		'
		--SEPARACION DE CADENA PARA FORMAR TABLA---------------------------------------------------------
	END
ELSE
	BEGIN
		SET @Query=@Query+'
		SET @Buscar=QUOTENAME(''%'' +(LTRIM(RTRIM('''+@TMP+''')))+ ''%'','''''''')'
	END

SET @Query=@Query+'
		DECLARE @TableName NVARCHAR(256), @ColumnName NVARCHAR(128)
		SET  @TableName = '''''
	
IF((SELECT CHARINDEX('IN',@TMP))>0)
	BEGIN
		SET @Query=@Query+'
		SET @Ciclos=(SELECT MAX(N) FROM @Tablas)
		WHILE (@Ciclos>0)'
	END	
ELSE
	BEGIN
		SET @Query=@Query+'
		WHILE @TableName IS NOT NULL'
	END
	
		SET @Query=@Query+'
		BEGIN
		SET @ColumnName = '''''

IF((SELECT CHARINDEX('IN',@TMP))>0)
	BEGIN
		SET @Query=@Query+'
		SET @TableName =(SELECT REPLACE(Tabla,'' '', '''')  FROM @Tablas WHERE N=@Ciclos)'
	END	
ELSE
	BEGIN
		SET @Query=@Query+'
		SET @TableName = 
		(
			SELECT MIN(QUOTENAME(TABLE_SCHEMA) + ''.'' + QUOTENAME(TABLE_NAME))
			FROM 	INFORMATION_SCHEMA.TABLES
			WHERE 		TABLE_TYPE = ''BASE TABLE''
				AND	QUOTENAME(TABLE_SCHEMA) + ''.'' + QUOTENAME(TABLE_NAME) > @TableName
				AND	OBJECTPROPERTY(
						OBJECT_ID(
							QUOTENAME(TABLE_SCHEMA) + ''.'' + QUOTENAME(TABLE_NAME)
							 ), ''IsMSShipped''
						       ) = 0
		)'
	END
		
SET @Query=@Query+'		
		WHILE (@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL)
		BEGIN
			SET @ColumnName =
			(
				SELECT MIN(QUOTENAME(COLUMN_NAME))
				FROM 	INFORMATION_SCHEMA.COLUMNS
				WHERE 		TABLE_SCHEMA	= PARSENAME(@TableName, 2)
					AND	TABLE_NAME	= PARSENAME(@TableName, 1)
					AND	DATA_TYPE IN (''char'', ''varchar'', ''nchar'', ''nvarchar'')
					AND	QUOTENAME(COLUMN_NAME) > @ColumnName
			)
	
			IF @ColumnName IS NOT NULL
			BEGIN
				INSERT INTO #Results
				EXEC
				(
					''SELECT '''''' + @TableName + ''.'' + @ColumnName + '''''', LEFT('' + @ColumnName + '', 3630) 
					FROM '' + @TableName + '' (NOLOCK) '' +
					'' WHERE '' + @ColumnName + '' LIKE '' + @Buscar
				)
			END
		END'	
		
IF((SELECT CHARINDEX('IN',@TMP))>0)
	BEGIN
		SET @Query=@Query+'
		SET @Ciclos = @Ciclos-1'
	END	

SET @Query=@Query+'
	END

	SELECT ColumnName AS [TABLA/COLUMNA] , ColumnValue AS [VALOR] FROM #Results
	DROP TABLE #Results
	
SET NOCOUNT OFF'

IF(@Print=1)
BEGIN
	PRINT @Query 
END

EXECUTE sp_executesql  @Query 
 , N'@TMP NVARCHAR, @Print BIT ' 
 , @TMP = @TMP                 
 , @Print = @Print 
 
END
