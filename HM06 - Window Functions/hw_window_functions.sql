/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

-- У меня умирает ноубтук без этого ограничения
WITH 
SalesForReport AS
(
	SELECT i.InvoiceID, i.CustomerID, i.InvoiceDate, EOMONTH(i.InvoiceDate) AS EOMInvoice, SUM(il.Quantity * il.UnitPrice) AS InvoiceSum
	FROM Sales.Invoices AS i
	LEFT JOIN Sales.InvoiceLines AS il ON il.InvoiceID = i.InvoiceID
	WHERE i.InvoiceDate >= '2015-01-01'
	GROUP BY i.InvoiceID, i.CustomerID, i.InvoiceDate, EOMONTH(i.InvoiceDate)
),
SalesByMonth AS 
(
	SELECT 
		EOMInvoice, 
		SUM(InvoiceSum) AS TotalSalesByMonth
	FROM SalesForReport AS aggr
	GROUP BY EOMInvoice
)
SELECT r.InvoiceID, c.CustomerName, r.InvoiceDate, s.CumulativeTotal
FROM SalesForReport AS r
LEFT JOIN Sales.Customers AS c ON c.CustomerID = r.CustomerID
OUTER APPLY (
	SELECT 
		SUM(TotalSalesByMonth) AS CumulativeTotal
	FROM SalesByMonth AS aggr 
	WHERE aggr.EOMInvoice <= r.EOMInvoice
) AS s
ORDER BY r.InvoiceDate


/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
SET STATISTICS TIME, IO ON;
WITH 
SalesForReport AS
(
	SELECT i.InvoiceID, i.CustomerID, i.InvoiceDate, EOMONTH(i.InvoiceDate) AS EOMInvoice, SUM(il.Quantity * il.UnitPrice) AS InvoiceSum
	FROM Sales.Invoices AS i
	LEFT JOIN Sales.InvoiceLines AS il ON il.InvoiceID = i.InvoiceID
	WHERE i.InvoiceDate >= '2015-01-01'
	GROUP BY i.InvoiceID, i.CustomerID, i.InvoiceDate, EOMONTH(i.InvoiceDate)
),
SalesByMonth AS 
(
	SELECT 
		EOMInvoice, 
		SUM(InvoiceSum) AS TotalSalesByMonth
	FROM SalesForReport AS aggr
	GROUP BY EOMInvoice
),
SalesCumulative AS (
	SELECT 
		EOMInvoice,
		SUM(TotalSalesByMonth) OVER (ORDER BY EOMInvoice ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeTotal
	FROM SalesByMonth
)
SELECT r.InvoiceID, c.CustomerName, r.InvoiceDate, ct.CumulativeTotal
FROM SalesForReport AS r
LEFT JOIN Sales.Customers AS c ON c.CustomerID = r.CustomerID
LEFT JOIN SalesCumulative AS ct ON ct.EOMInvoice = r.EOMInvoice
ORDER BY r.InvoiceDate;

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/
SELECT * 
FROM (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY EOMONTH(i.InvoiceDate) ORDER BY SUM(il.Quantity) DESC) AS PlaceByQuantity,
		EOMONTH(i.InvoiceDate) AS EOMInvoice,
		il.StockItemID,
		SUM(il.Quantity) AS SalesQuantityByMonth
	FROM Sales.InvoiceLines AS il
	LEFT JOIN Sales.Invoices AS i ON il.InvoiceID = i.InvoiceID
	WHERE YEAR(i.InvoiceDate) = 2016
	GROUP BY EOMONTH(i.InvoiceDate), il.StockItemID
	) AS T
WHERE PlaceByQuantity < 3
ORDER BY EOMInvoice

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/
SELECT w.StockItemID, w.StockItemName, w.Brand, w.UnitPrice, w.RecommendedRetailPrice
	-- * пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
	,ROW_NUMBER() OVER (PARTITION BY LEFT(w.StockItemName, 1) ORDER BY w.StockItemName) AS ABCSort
	-- * посчитайте общее количество товаров и выведете полем в этом же запросе
	,SUM(s.QuantityOnHand) OVER () AS AllQuantity
	-- * посчитайте общее количество товаров в зависимости от первой буквы названия товара
	,SUM(s.QuantityOnHand) OVER (PARTITION BY LEFT(w.StockItemName, 1)) AS QuantityByFirstLetter
	-- * отобразите следующий id товара исходя из того, что порядок отображения товаров по имени
	,LEAD(w.StockItemID) OVER (ORDER BY w.StockItemName) AS NextStockIdOrderedByName
	-- * предыдущий ид товара с тем же порядком отображения (по имени)
	,LAG(w.StockItemID) OVER (ORDER BY w.StockItemName) AS PreviuosStockIdOrderedByName
	-- * названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
	,LAG(w.StockItemName, 2, 'No items') OVER (ORDER BY w.StockItemName) AS PrevPrevItemNameOrderedByName
	-- * сформируйте 30 групп товаров по полю вес товара на 1 шт
	,NTILE(30) OVER (ORDER BY w.TypicalWeightPerUnit) AS GroupByWeightPerUnit
FROM Warehouse.StockItems AS w
LEFT JOIN Warehouse.StockItemHoldings AS s On s.StockItemID = w.StockItemID

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/
WITH LastSalerCustomerContact AS (
	SELECT CustomerID, SalespersonPersonID, MAX(InvoiceID) AS LastInvoiceId 
	FROM Sales.Invoices 
	GROUP BY CustomerID, SalespersonPersonID
)
SELECT p.PersonID, p.FullName, c.CustomerID, c.CustomerName, s.InvoiceDate, s.InvoiceSum
FROM Application.People AS p
LEFT JOIN LastSalerCustomerContact AS l ON l.SalespersonPersonID = p.PersonID
LEFT JOIN Sales.Customers AS c ON c.CustomerID = l.CustomerID
LEFT JOIN (
	SELECT i.InvoiceID, i.InvoiceDate, SUM(il.UnitPrice * il.Quantity) AS InvoiceSum 
	FROM Sales.Invoices AS i
	LEFT JOIN [Sales].[InvoiceLines] AS il ON il.InvoiceID = i.InvoiceID
	GROUP BY i.InvoiceID, i.InvoiceDate
) AS s ON s.InvoiceID = l.LastInvoiceId

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT c.CustomerID, c.CustomerName, p.StockItemID, p.UnitPrice, i.InvoiceDate AS  LastInvoiceDate
FROM Sales.Customers AS c
OUTER APPLY (
	SELECT TOP 2 il.StockItemID, il.UnitPrice, MAX(il.InvoiceID) AS LastSaleId
	FROM Sales.Invoices AS i
	LEFT JOIN Sales.InvoiceLines AS il On i.InvoiceID = il.InvoiceID
	WHERE i.CustomerID = c.CustomerID
	GROUP BY il.StockItemID, il.UnitPrice
	ORDER BY il.UnitPrice DESC
) AS p
LEFT JOIN Sales.Invoices AS i ON i.InvoiceID = p.LastSaleId
ORDER BY c.CustomerID

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 