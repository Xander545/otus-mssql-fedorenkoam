/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Опционально - если вы знакомы с insert, update, merge, то загрузить эти данные в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 
*/

-- Переменная, в которую считаем XML-файл
DECLARE @xmlDocument  xml

-- Считываем XML-файл в переменную
-- !!! измените путь к XML-файлу
SELECT @xmlDocument = BulkColumn
FROM OPENROWSET (BULK 'C:\projects\otus\otus-mssql-fedorenkoam\HM08 - XML, JSON\StockItems.xml', SINGLE_CLOB) AS data;
DECLARE @docHandle int;
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument;

IF object_id('tempdb..#XML') is not null DROP TABLE #XML

SELECT *
INTO #XML
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] nvarchar(100) '@Name',
	[SupplierID] int 'SupplierID',
	[UnitPackageID] int 'Package/UnitPackageID',
	[OuterPackageID] int 'Package/OuterPackageID',
	[QuantityPerOuter] int 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] decimal(18,3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] int 'LeadTimeDays',
	[IsChillerStock] bit 'IsChillerStock',
	[TaxRate] decimal(18,3) 'TaxRate',
	[UnitPrice] decimal(18,2) 'UnitPrice'
);

-- SELECT * FROM #XML

MERGE INTO Warehouse.StockItems AS tgt  
USING (
	SELECT 
		StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice
		-- Добавим поля, которые в целевой таблице NOT NULL, чтоб сработал INSERT
		,1 AS LastEditedBy
	FROM #XML
	) as src (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
ON tgt.StockItemName = src.StockItemName  
WHEN MATCHED THEN  
UPDATE SET 
	SupplierID = src.SupplierID, 
	UnitPackageID = src.UnitPackageID, 
	OuterPackageID = src.OuterPackageID, 
	QuantityPerOuter = src.QuantityPerOuter, 
	TypicalWeightPerUnit = src.TypicalWeightPerUnit, 
	LeadTimeDays = src.LeadTimeDays, 
	IsChillerStock = src.IsChillerStock, 
	TaxRate = src.TaxRate, 
	UnitPrice = src.UnitPrice,
	LastEditedBy = src.LastEditedBy
WHEN NOT MATCHED BY TARGET THEN  
INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy) 
	VALUES (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
;


/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

SELECT 	
	[StockItemName] AS '@Name',
	[SupplierID] AS 'SupplierID',
	[UnitPackageID] AS 'Package/UnitPackageID',
	[OuterPackageID] AS 'Package/OuterPackageID',
	[QuantityPerOuter] AS 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] AS 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] AS 'LeadTimeDays',
	[IsChillerStock] AS 'IsChillerStock',
	[TaxRate] AS 'TaxRate',
	[UnitPrice] AS 'UnitPrice' 
FROM [Warehouse].[StockItems]
FOR XML PATH('Item'), ROOT('StockItems')
;

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT 
	i.StockItemID, i.StockItemName, i.CustomFields, 
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
	JSON_VALUE(CustomFields, '$.Tags[1]') AS FirstTag
FROM Warehouse.StockItems AS i
;

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

SELECT 
	i.StockItemID, i.StockItemName, ParsedTag
FROM Warehouse.StockItems AS i
OUTER APPLY OPENJSON (CustomFields, '$.Tags')
WITH (
    ParsedTag nvarchar(100) '$'
)
WHERE ParsedTag = 'Vintage'
;

WITH NeedleItems AS (
	SELECT i.StockItemID
	FROM Warehouse.StockItems AS i
	OUTER APPLY OPENJSON (CustomFields, '$.Tags') WITH (ParsedTag nvarchar(100) '$')
	WHERE ParsedTag = 'Vintage'
)
SELECT 
	i.StockItemID, i.StockItemName, STRING_AGG(ParsedTag, ', ') AS ConcatedTags
FROM NeedleItems AS n
LEFT JOIN Warehouse.StockItems AS i ON i.StockItemID = n.StockItemID
OUTER APPLY OPENJSON (CustomFields, '$.Tags') WITH (ParsedTag nvarchar(100) '$')
GROUP BY i.StockItemID, i.StockItemName
;
