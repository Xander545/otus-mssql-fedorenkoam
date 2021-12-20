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
DECLARE @last_day AS date;
SET @last_day = '2015-12-31';
WITH 
SalesForReport AS
(
	SELECT i.InvoiceID, i.CustomerID, i.InvoiceDate, EOMONTH(i.InvoiceDate) AS EOMInvoice, SUM(il.Quantity * il.UnitPrice) AS InvoiceSum
	FROM Sales.Invoices AS i
	LEFT JOIN Sales.InvoiceLines AS il ON il.InvoiceID = i.InvoiceID
	WHERE i.InvoiceDate BETWEEN '2015-01-01' AND @last_day
	GROUP BY i.InvoiceID, i.CustomerID, i.InvoiceDate, EOMONTH(i.InvoiceDate)
),
SalesByMonth AS 
(
	SELECT EOMInvoice, SUM(InvoiceSum) AS TotalSalesByMonth
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

напишите здесь свое решение

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

напишите здесь свое решение

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

напишите здесь свое решение

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

напишите здесь свое решение

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

напишите здесь свое решение

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 