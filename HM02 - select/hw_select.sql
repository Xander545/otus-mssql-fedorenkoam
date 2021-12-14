/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
FROM [WideWorldImporters].[Warehouse].[StockItems]
WHERE StockItemName like '%urgent%'
   OR StockItemName like 'Animal%'
;

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT s.SupplierID, s.SupplierName
FROM Purchasing.Suppliers AS s
LEFT JOIN Purchasing.PurchaseOrders AS o ON o.SupplierID = s.SupplierID
WHERE o.SupplierID is NULL
GROUP BY s.SupplierID, s.SupplierName;

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/


SELECT DISTINCT
	o.OrderID, 
	o.OrderDate,
	CONVERT(varchar(10), o.OrderDate, 104) AS OrderDateChar104,
	DATENAME(m, o.OrderDate) AS MonthOfOrder,
	DATENAME(q, o.OrderDate) AS QuaterOfOrder,
	-- Математика или ...
	-- ABS((DATEPART(m, o.OrderDate) - 1) / 4) + 1 AS ThirdYearOrder,
	-- ... или CASE ?
	CASE 
		WHEN DATEPART(m, o.OrderDate) BETWEEN 1 AND 4 THEN 1
		WHEN DATEPART(m, o.OrderDate) BETWEEN 5 AND 8 THEN 2
		ELSE 3
	END AS ThirdYearOrder,
	c.CustomerName
FROM Sales.Orders AS o
LEFT JOIN Sales.OrderLines AS l ON o.OrderID = l.OrderID
LEFT JOIN Sales.Customers AS c ON c.CustomerID = o.CustomerID
WHERE (l.UnitPrice > 100 OR l.Quantity > 20)
  AND o.PickingCompletedWhen IS NOT NULL
ORDER BY QuaterOfOrder, ThirdYearOrder, o.OrderDate
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT 
	dm.DeliveryMethodName,
	o.ExpectedDeliveryDate, 
	s.SupplierName, 
	p.FullName AS ContactPerson
FROM [Purchasing].[PurchaseOrders] AS o
LEFT JOIN [Application].[DeliveryMethods] AS dm ON o.DeliveryMethodID = dm.DeliveryMethodID
LEFT JOIN [Purchasing].[Suppliers] AS s ON s.SupplierID = o.SupplierID
LEFT JOIN [Application].[People] AS p ON p.PersonID = o.ContactPersonID
WHERE o.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31'
  AND dm.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
  AND o.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

-- Непонятно продажа - это заказ в целом или одна позиция? Вывожу заказ, 
-- но можно расшить и до позиции, соответственно топ будет немного другим
SELECT TOP 10 o.OrderID, o.OrderDate, p.FullName as SalespersonPerson, c.CustomerName
FROM Sales.Orders as o
LEFT JOIN [Application].[People] AS p ON p.PersonID = o.SalespersonPersonID
LEFT JOIN [Sales].[Customers] AS c ON c.CustomerID = o.CustomerID
ORDER BY o.OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT c.CustomerID, c.CustomerName, c.PhoneNumber
FROM [Warehouse].[StockItems] AS i
LEFT JOIN [Sales].[OrderLines] AS l ON i.StockItemID = l.StockItemID
LEFT JOIN [Sales].[Orders] AS o ON o.OrderID = l.OrderID
LEFT JOIN [Sales].[Customers] AS c ON o.CustomerID = c.CustomerID
WHERE i.StockItemName = 'Chocolate frogs 250g'

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
	YEAR(i.InvoiceDate) AS YearOfInvoice,
	MONTH(i.InvoiceDate) AS MonthOfInvoice,
	AVG(l.UnitPrice) AS AvgPriceByMonth,
	SUM(l.Quantity) AS QuantityByMonth
FROM Sales.Invoices AS i
LEFT JOIN Sales.InvoiceLines AS l ON i.InvoiceID = l.InvoiceID
GROUP BY 
	YEAR(i.InvoiceDate),
	MONTH(i.InvoiceDate)
ORDER BY 
	YEAR(i.InvoiceDate),
	MONTH(i.InvoiceDate)

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

-- 8.1 Основной ответ
SELECT 
	YEAR(i.InvoiceDate) AS YearOfInvoice,
	MONTH(i.InvoiceDate) AS MonthOfInvoice,
	SUM(l.UnitPrice * l.Quantity) AS SumPriceByMonth
FROM Sales.Invoices AS i
LEFT JOIN Sales.InvoiceLines AS l ON i.InvoiceID = l.InvoiceID
GROUP BY 
	YEAR(i.InvoiceDate),
	MONTH(i.InvoiceDate)
HAVING
	SUM(l.UnitPrice * l.Quantity) > 10000
ORDER BY 
	YEAR(i.InvoiceDate),
	MONTH(i.InvoiceDate)

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

-- 9.1 Основной ответ
SELECT 
	YEAR(i.InvoiceDate) AS YearOfInvoice,
	MONTH(i.InvoiceDate) AS MonthOfInvoice,
	itm.StockItemName,
	SUM(l.UnitPrice * l.Quantity) AS SumPriceByMonthItem,
	MIN(i.InvoiceDate) AS FirstSaleDateInMonth,
	SUM(l.Quantity) AS SumQuantityByMonthItem
FROM Sales.Invoices AS i
LEFT JOIN Sales.InvoiceLines AS l ON i.InvoiceID = l.InvoiceID
LEFT JOIN Warehouse.StockItems AS itm ON itm.StockItemID = l.StockItemID
GROUP BY 
	YEAR(i.InvoiceDate),
	MONTH(i.InvoiceDate),
	itm.StockItemName
HAVING
	SUM(l.Quantity) < 50
ORDER BY 
	YEAR(i.InvoiceDate),
	MONTH(i.InvoiceDate),
	itm.StockItemName

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/


-- 8.2 Ответ с месяцами и нулями
-- Собираем "все месяца", тут все месяца, в которых были продажи, но можно итерироваться по любым границам
DECLARE @first_month Date, @last_month Date, @iterator Date;
CREATE TABLE #MONTH (ReportMonth date);
SELECT @first_month = MIN(EOMONTH(OrderDate)), @last_month = MAX(EOMONTH(OrderDate)) FROM [Sales].[Orders]
SET @iterator = @first_month
WHILE @iterator < @last_month
BEGIN
	SET @iterator = DATEADD(mm, 1, @iterator)
	INSERT INTO #MONTH (ReportMonth) VALUES (@iterator)
END;

-- Присоединяем к таблице с месяцами вычисленную ранее таблицу с ответом
SELECT 
	YEAR(m.ReportMonth) AS YearForReport, MONTH(m.ReportMonth) AS MonthForReport, 
	COALESCE(AnswerTable.SumPriceByMonth, 0) AS SalesSum
FROM #MONTH AS m
LEFT JOIN (
			SELECT 
				YEAR(i.InvoiceDate) AS YearOfInvoice, MONTH(i.InvoiceDate) AS MonthOfInvoice, 
				SUM(l.UnitPrice * l.Quantity) AS SumPriceByMonth
			FROM Sales.Invoices AS i
			LEFT JOIN Sales.InvoiceLines AS l ON i.InvoiceID = l.InvoiceID
			GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
			HAVING SUM(l.UnitPrice * l.Quantity) > 10000
	) AS AnswerTable ON YEAR(m.ReportMonth) = AnswerTable.YearOfInvoice 
					AND MONTH(m.ReportMonth) = AnswerTable.MonthOfInvoice
ORDER BY YEAR(m.ReportMonth), MONTH(m.ReportMonth)