/*
	1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), и не сделали ни одной продажи 04 июля 2015 года. 
	Вывести ИД сотрудника и его полное имя. Продажи смотреть в таблице Sales.Invoices.
*/
SELECT p.PersonID, p.FullName
FROM Application.People AS p
WHERE p.PersonID NOT IN (
						SELECT i.SalespersonPersonID 
						FROM Sales.Invoices AS i 
						WHERE i.InvoiceDate BETWEEN '20150704' AND '20150705'
						)

-- 2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. Вывести: ИД товара, наименование товара, цена.
SELECT itm.StockItemID, itm.StockItemName, itm.UnitPrice
FROM [Warehouse].[StockItems] AS itm
WHERE UnitPrice IN (SELECT MIN(UnitPrice) FROM [Warehouse].[StockItems])

SELECT itm.StockItemID, itm.StockItemName, itm.UnitPrice
FROM [Warehouse].[StockItems] AS itm
WHERE UnitPrice <= ALL (SELECT UnitPrice FROM [Warehouse].[StockItems])

-- 3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей из Sales.CustomerTransactions. Представьте несколько способов (в том числе с CTE). 
-- 3.1 Подзапрос в WHERE
SELECT c.CustomerID, c.CustomerName
FROM [Sales].[Customers] AS c
WHERE CustomerID IN (
					SELECT TOP 5 ct.CustomerID
					FROM [Sales].[CustomerTransactions] AS ct
					ORDER BY ct.TransactionAmount DESC
					)

-- 3.2 Подзапрос в FROM 
SELECT c.CustomerID, c.CustomerName, ct.TransactionAmount
FROM (
	SELECT TOP 5 CustomerID, TransactionAmount
	FROM [Sales].[CustomerTransactions]
	ORDER BY TransactionAmount DESC
	) AS ct
LEFT JOIN [Sales].[Customers] AS c ON c.CustomerID = ct.CustomerID


-- 3.3 Выборка над CTE
WITH MostPayfull
AS
(
	SELECT TOP 5 CustomerID, TransactionAmount
	FROM [Sales].[CustomerTransactions]
	ORDER BY TransactionAmount DESC
)
SELECT c.CustomerID, c.CustomerName, m.TransactionAmount
FROM MostPayfull AS m
LEFT JOIN [Sales].[Customers] AS c ON c.CustomerID = m.CustomerID
;


-- 4. Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров, 
-- а также имя сотрудника, который осуществлял упаковку заказов (PackedByPersonID).
WITH Top3ExpensiveItems AS
(
	SELECT TOP 3 itm.StockItemID
	FROM [Warehouse].[StockItems] AS itm
	ORDER BY UnitPrice DESC
),

RequiredInvoices AS 
(
	SELECT i.PackedByPersonID, c.DeliveryCityID
	FROM [Sales].[InvoiceLines] AS il
	LEFT JOIN [Sales].[Invoices] AS i ON il.InvoiceID = i.InvoiceID
	LEFT JOIN [Sales].[Customers] AS c on c.CustomerID = i.CustomerID
	WHERE il.StockItemID IN (SELECT StockItemID FROM Top3ExpensiveItems)
	GROUP BY i.PackedByPersonID, c.DeliveryCityID
)
SELECT c.CityName, p.FullName AS PackedByPersonName
FROM RequiredInvoices AS r
LEFT JOIN [Application].[Cities] AS c ON r.DeliveryCityID = c.CityID
LEFT JOIN [Application].[People] AS p ON p.PersonID = r.PackedByPersonID

-- Опционально:
-- 5. Объясните, что делает и оптимизируйте запрос: 
/*
SELECT Invoices.InvoiceID, Invoices.InvoiceDate, (SELECT People.FullName
 FROM Application.People
 WHERE People.PersonID = Invoices.SalespersonPersonID
) AS SalesPersonName, SalesTotals.TotalSumm AS TotalSummByInvoice, (SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
 FROM Sales.OrderLines
 WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
     FROM Sales.Orders
     WHERE Orders.PickingCompletedWhen IS NOT NULL    
         AND Orders.OrderId = Invoices.OrderId)    
) AS TotalSummForPickedItems FROM Sales.Invoices JOIN (SELECT InvoiceId, SUM(QuantityUnitPrice) AS TotalSumm FROM Sales.InvoiceLines GROUP BY InvoiceId HAVING SUM(QuantityUnitPrice) > 27000) AS SalesTotals
 ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC 
Можно двигаться как в сторону улучшения читабельности запроса, так и в сторону упрощения плана\ускорения. 
Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
Напишите ваши рассуждения по поводу оптимизации.
*/

-- 5.1 Переформатировал запрос так, чтобы мне было удобнее читать
SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate, 
	(
		SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName, 
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(
		SELECT SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (
									SELECT Orders.OrderId 
									FROM Sales.Orders
									WHERE Orders.PickingCompletedWhen IS NOT NULL    
									  AND Orders.OrderId = Invoices.OrderId)    
	) AS TotalSummForPickedItems 
FROM Sales.Invoices 
JOIN (
		SELECT InvoiceId, SUM(QuantityUnitPrice) AS TotalSumm 
		FROM Sales.InvoiceLines 
		GROUP BY InvoiceId 
		HAVING SUM(QuantityUnitPrice) > 27000
		) AS SalesTotals ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC 

-- 5.2 Исправил опечатку, чтоб он вообще работал
SET STATISTICS IO, TIME ON

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate, 
	(
		SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName, 
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(
		SELECT SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (
									SELECT Orders.OrderId 
									FROM Sales.Orders
									WHERE Orders.PickingCompletedWhen IS NOT NULL    
									  AND Orders.OrderId = Invoices.OrderId)    
	) AS TotalSummForPickedItems 
FROM Sales.Invoices 
JOIN (
		SELECT InvoiceId, SUM(Quantity * UnitPrice) AS TotalSumm 
		FROM Sales.InvoiceLines 
		GROUP BY InvoiceId 
		HAVING SUM(Quantity * UnitPrice) > 27000
		) AS SalesTotals ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC 
;
/*
	Таблица "OrderLines". Сканирований 16, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 508, физических операций чтения LOB 3, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 790, операций чтения LOB страничного сервера, выполненных с упреждением 0.
	Таблица "OrderLines". Считано сегментов 1, пропущено 0.
	Таблица "InvoiceLines". Сканирований 16, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 502, физических операций чтения LOB 3, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 778, операций чтения LOB страничного сервера, выполненных с упреждением 0.
	Таблица "InvoiceLines". Считано сегментов 1, пропущено 0.
	Таблица "Orders". Сканирований 9, логических операций чтения 725, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 557, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
	Таблица "Invoices". Сканирований 9, логических операций чтения 11994, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 10616, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
	Таблица "People". Сканирований 9, логических операций чтения 28, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
	Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
*/

-- 5.3 Пошёл гуглить разницу между Orders и Invoices...
-- Order - это заказ товаров от покупателя продавцу
-- Invoice - это счет на оплату от продавца покупателю

-- 5.4 Осознал суть запроса: Выбираются счета, от продавца клиентам, у которых сумма больше чем 27000. 
-- Для этих счетов выбирается: код, дата, продажник, сумма счета к оплате и сумма фактически собранного заказа...
-- Наверное, сумма счета к оплате и сумма фактически собранного заказа должны быть равны. И суть запроса - найти расхождения. Иначе вообще бессмысленно выбирать именно так.

-- 5.5 Переписываю запрос. Мне не нравятся такого рода подзапросы внутри SELECT и потому я помещу их в условие FROM, выбрав предварительно через CTE коды интересующих меня счетов.
SET STATISTICS IO, TIME ON
;
WITH InvocesCTE
AS (
	SELECT InvoiceId, SUM(Quantity * UnitPrice) AS TotalSumm 
	FROM Sales.InvoiceLines 
	GROUP BY InvoiceId 
	HAVING SUM(Quantity * UnitPrice) > 27000
)
SELECT 	
	i.InvoiceID, 
	i.InvoiceDate, 
	p.FullName,
	ic.TotalSumm,
	(
		SELECT SUM(ol.PickedQuantity * ol.UnitPrice)
		FROM Sales.Orders AS o
		LEFT JOIN Sales.OrderLines AS ol ON o.OrderID = ol.OrderID
		WHERE o.PickingCompletedWhen IS NOT NULL
		  AND i.OrderID = o.OrderID
	) AS TotalSummForPickedItems
FROM InvocesCTE AS ic
LEFT JOIN Sales.Invoices AS i ON i.InvoiceID = ic.InvoiceID
LEFT JOIN Application.People AS p on i.SalespersonPersonID = p.PersonID
;
/*
	Таблица "OrderLines". Сканирований 16, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 326, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
	Таблица "OrderLines". Считано сегментов 1, пропущено 0.
	Таблица "InvoiceLines". Сканирований 16, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 322, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
	Таблица "InvoiceLines". Считано сегментов 1, пропущено 0.
	Таблица "Orders". Сканирований 9, логических операций чтения 725, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
	Таблица "Invoices". Сканирований 9, логических операций чтения 11994, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
	Таблица "People". Сканирований 9, логических операций чтения 28, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
	Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
*/
