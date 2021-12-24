/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/


DECLARE @clients AS VARCHAR(MAX), @query AS VARCHAR(MAX)

SELECT @clients = STRING_AGG(CAST('[' + c.CustomerName + ']' AS VARCHAR(MAX)), ',') 
FROM [Sales].[Customers] AS c

SET @query = 
'
SELECT 
	CONVERT(VARCHAR(10), InvoiceMonth, 104) AS InvoiceMonthString,
	' + @clients + '
FROM (
	SELECT 
			DATEADD(DAY, - 1 * DAY(i.InvoiceDate) + 1, i.InvoiceDate) AS InvoiceMonth,
			c.CustomerName,
			i.InvoiceID
	FROM [Sales].[Invoices] AS i
	LEFT JOIN [Sales].[Customers] AS c ON c.CustomerID = i.CustomerID
) AS p
PIVOT  
(  
  COUNT(InvoiceID)  
  FOR CustomerName IN (' + @clients + ')  
) AS PivotTable
ORDER BY InvoiceMonth; 
';

exec (@query)

