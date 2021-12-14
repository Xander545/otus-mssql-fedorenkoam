/*
	1. �������� ����������� (Application.People), ������� �������� ������������ (IsSalesPerson), � �� ������� �� ����� ������� 04 ���� 2015 ����. 
	������� �� ���������� � ��� ������ ���. ������� �������� � ������� Sales.Invoices.
*/
SELECT p.PersonID, p.FullName
FROM Application.People AS p
WHERE p.PersonID NOT IN (
						SELECT i.SalespersonPersonID 
						FROM Sales.Invoices AS i 
						WHERE i.InvoiceDate BETWEEN '20150704' AND '20150705'
						)

-- 2. �������� ������ � ����������� ����� (�����������). �������� ��� �������� ����������. �������: �� ������, ������������ ������, ����.
SELECT itm.StockItemID, itm.StockItemName, itm.UnitPrice
FROM [Warehouse].[StockItems] AS itm
WHERE UnitPrice IN (SELECT MIN(UnitPrice) FROM [Warehouse].[StockItems])

SELECT itm.StockItemID, itm.StockItemName, itm.UnitPrice
FROM [Warehouse].[StockItems] AS itm
WHERE UnitPrice <= ALL (SELECT UnitPrice FROM [Warehouse].[StockItems])

-- 3. �������� ���������� �� ��������, ������� �������� �������� ���� ������������ �������� �� Sales.CustomerTransactions. ����������� ��������� �������� (� ��� ����� � CTE). 
-- 3.1 ��������� � WHERE
SELECT c.CustomerID, c.CustomerName
FROM [Sales].[Customers] AS c
WHERE CustomerID IN (
					SELECT TOP 5 ct.CustomerID
					FROM [Sales].[CustomerTransactions] AS ct
					ORDER BY ct.TransactionAmount DESC
					)

-- 3.2 ��������� � FROM 
SELECT c.CustomerID, c.CustomerName, ct.TransactionAmount
FROM (
	SELECT TOP 5 CustomerID, TransactionAmount
	FROM [Sales].[CustomerTransactions]
	ORDER BY TransactionAmount DESC
	) AS ct
LEFT JOIN [Sales].[Customers] AS c ON c.CustomerID = ct.CustomerID


-- 3.3 ������� ��� CTE
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


-- 4. �������� ������ (�� � ��������), � ������� ���� ���������� ������, �������� � ������ ����� ������� �������, 
-- � ����� ��� ����������, ������� ����������� �������� ������� (PackedByPersonID).
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

-- �����������:
-- 5. ���������, ��� ������ � ������������� ������: 
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
����� ��������� ��� � ������� ��������� ������������� �������, ��� � � ������� ��������� �����\���������. 
�������� ������������������ �������� ����� ����� SET STATISTICS IO, TIME ON. ���� ������� � ������� ��������, �� ����������� �� (����� � ������� ����� ��������� �����). 
�������� ���� ����������� �� ������ �����������.
*/

-- 5.1 ���������������� ������ ���, ����� ��� ���� ������� ������
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

-- 5.2 �������� ��������, ���� �� ������ �������
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
	������� "OrderLines". ������������ 16, ���������� �������� ������ 0, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 508, ���������� �������� ������ LOB 3, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 790, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
	������� "OrderLines". ������� ��������� 1, ��������� 0.
	������� "InvoiceLines". ������������ 16, ���������� �������� ������ 0, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 502, ���������� �������� ������ LOB 3, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 778, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
	������� "InvoiceLines". ������� ��������� 1, ��������� 0.
	������� "Orders". ������������ 9, ���������� �������� ������ 725, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 557, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
	������� "Invoices". ������������ 9, ���������� �������� ������ 11994, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 10616, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
	������� "People". ������������ 9, ���������� �������� ������ 28, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
	������� "Worktable". ������������ 0, ���������� �������� ������ 0, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
*/

-- 5.3 ����� ������� ������� ����� Orders � Invoices...
-- Order - ��� ����� ������� �� ���������� ��������
-- Invoice - ��� ���� �� ������ �� �������� ����������

-- 5.4 ������� ���� �������: ���������� �����, �� �������� ��������, � ������� ����� ������ ��� 27000. 
-- ��� ���� ������ ����������: ���, ����, ���������, ����� ����� � ������ � ����� ���������� ���������� ������...
-- ��������, ����� ����� � ������ � ����� ���������� ���������� ������ ������ ���� �����. � ���� ������� - ����� �����������. ����� ������ ������������ �������� ������ ���.

-- 5.5 ����������� ������. ��� �� �������� ������ ���� ���������� ������ SELECT � ������ � ������ �� � ������� FROM, ������ �������������� ����� CTE ���� ������������ ���� ������.
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
	������� "OrderLines". ������������ 16, ���������� �������� ������ 0, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 326, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
	������� "OrderLines". ������� ��������� 1, ��������� 0.
	������� "InvoiceLines". ������������ 16, ���������� �������� ������ 0, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 322, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
	������� "InvoiceLines". ������� ��������� 1, ��������� 0.
	������� "Orders". ������������ 9, ���������� �������� ������ 725, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
	������� "Invoices". ������������ 9, ���������� �������� ������ 11994, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
	������� "People". ������������ 9, ���������� �������� ������ 28, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
	������� "Worktable". ������������ 0, ���������� �������� ������ 0, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
*/
