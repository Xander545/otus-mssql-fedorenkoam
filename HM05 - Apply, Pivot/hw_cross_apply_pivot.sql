/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

SELECT 
	CONVERT(VARCHAR(10), InvoiceMonth, 104) AS InvoiceMonthString,
	[Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND]
FROM (
	SELECT 
			DATEADD(DAY, - 1 * DAY(i.InvoiceDate) + 1, i.InvoiceDate) AS InvoiceMonth,
			SUBSTRING(c.CustomerName, CHARINDEX('(', c.CustomerName) + 1, CHARINDEX(')', c.CustomerName) - CHARINDEX('(', c.CustomerName) - 1) as ShortName,
			i.InvoiceID
	FROM [Sales].[Invoices] AS i
	LEFT JOIN [Sales].[Customers] AS c ON c.CustomerID = i.CustomerID
	WHERE c.CustomerID BETWEEN 2 AND 6
) AS p
PIVOT  
(  
  COUNT(InvoiceID)  
  FOR ShortName IN ([Peeples Valley, AZ], [Gasport, NY], [Jessie, ND], [Medicine Lodge, KS], [Sylvanite, MT])  
) AS PivotTable
ORDER BY InvoiceMonth; 


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT CustomerName, AddressLine
FROM (
	SELECT c.CustomerName, DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2
	FROM Sales.Customers AS c
	WHERE c.CustomerName LIKE '%Tailspin Toys%'
) AS p
UNPIVOT  
   (AddressLine FOR Customer IN   
      (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)  
)AS unpvt; 

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT CountryID, CountryName, Code
FROM (
	SELECT CountryID, CountryName, IsoAlpha3Code, CAST(IsoNumericCode AS nvarchar(3)) AS IsoNumericCode
	FROM Application.Countries
) AS p
UNPIVOT  
   (Code FOR Countries IN   
      (IsoAlpha3Code, IsoNumericCode)
)AS unpvt; 

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT c.CustomerID, c.CustomerName, p.StockItemID, p.UnitPrice, p.InvoiceDate
FROM Sales.Customers AS c
OUTER APPLY (
	SELECT TOP 2 il.StockItemID, il.UnitPrice, i.InvoiceDate
	FROM Sales.Invoices AS i
	LEFT JOIN Sales.InvoiceLines AS il On i.InvoiceID = il.InvoiceID
	WHERE i.CustomerID = c.CustomerID
	ORDER BY il.UnitPrice DESC
) AS p
