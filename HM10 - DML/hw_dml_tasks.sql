/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
0. Экономим калории, создаем временную таблицу для INSERT и MERGE(INSERT/UPDATE)
*/

-- DROP TABLE [Sales].[Customers_test]
SELECT TOP 5 '[HMinsert#' + CAST(ROW_NUMBER() OVER (ORDER BY CustomerName) AS VARCHAR) + ']' + [CustomerName] as CustomerName
           ,[BillToCustomerID],[CustomerCategoryID],[BuyingGroupID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID]
           ,[DeliveryCityID],[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent]
           ,[IsOnCreditHold],[PaymentDays],[PhoneNumber],[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL],[DeliveryAddressLine1]
           ,[DeliveryAddressLine2],[DeliveryPostalCode],[DeliveryLocation],[PostalAddressLine1],[PostalAddressLine2],[PostalPostalCode],[LastEditedBy]
INTO [Sales].[Customers_test]
FROM [Sales].[Customers]

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/
INSERT INTO [Sales].[Customers]
           ([CustomerName],[BillToCustomerID],[CustomerCategoryID],[BuyingGroupID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID],[DeliveryCityID]
           ,[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber]
           ,[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL],[DeliveryAddressLine1],[DeliveryAddressLine2],[DeliveryPostalCode],[DeliveryLocation]
           ,[PostalAddressLine1],[PostalAddressLine2],[PostalPostalCode],[LastEditedBy])
SELECT [CustomerName],[BillToCustomerID],[CustomerCategoryID],[BuyingGroupID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID]
           ,[DeliveryCityID],[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent]
           ,[IsOnCreditHold],[PaymentDays],[PhoneNumber],[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL],[DeliveryAddressLine1]
           ,[DeliveryAddressLine2],[DeliveryPostalCode],[DeliveryLocation],[PostalAddressLine1],[PostalAddressLine2],[PostalPostalCode],[LastEditedBy]
FROM [Sales].[Customers_test]

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/
DELETE FROM [Sales].[Customers]
--SELECT * FROM [Sales].[Customers]
WHERE [CustomerName] LIKE '%HMinsert%'
/*
3. Изменить одну запись, из добавленных через UPDATE
*/
UPDATE [Sales].[Customers]
SET [PaymentDays] = [PaymentDays] + 5
--SELECT * FROM [Sales].[Customers]
WHERE [CustomerName] LIKE '%HMinsert#2%'

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/
	MERGE [Sales].[Customers] AS target 
	USING (SELECT [CustomerName],[BillToCustomerID],[CustomerCategoryID],[BuyingGroupID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID],[DeliveryCityID]
           ,[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber]
           ,[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL],[DeliveryAddressLine1],[DeliveryAddressLine2],[DeliveryPostalCode],[DeliveryLocation]
           ,[PostalAddressLine1],[PostalAddressLine2],[PostalPostalCode],[LastEditedBy]
		   FROM [Sales].[Customers_test]) AS source ([CustomerName],[BillToCustomerID],[CustomerCategoryID],[BuyingGroupID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID],[DeliveryCityID]
           ,[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber]
           ,[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL],[DeliveryAddressLine1],[DeliveryAddressLine2],[DeliveryPostalCode],[DeliveryLocation]
           ,[PostalAddressLine1],[PostalAddressLine2],[PostalPostalCode],[LastEditedBy]) 
		ON
	 (target.[CustomerName] = source.[CustomerName]) 
	WHEN MATCHED 
		THEN UPDATE SET [PaymentDays] = source.[PaymentDays]
	WHEN NOT MATCHED 
		THEN INSERT ([CustomerName],[BillToCustomerID],[CustomerCategoryID],[BuyingGroupID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID],[DeliveryCityID]
           ,[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber]
           ,[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL],[DeliveryAddressLine1],[DeliveryAddressLine2],[DeliveryPostalCode],[DeliveryLocation]
           ,[PostalAddressLine1],[PostalAddressLine2],[PostalPostalCode],[LastEditedBy]) 
			VALUES ([CustomerName],[BillToCustomerID],[CustomerCategoryID],[BuyingGroupID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID],[DeliveryCityID]
           ,[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber]
           ,[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL],[DeliveryAddressLine1],[DeliveryAddressLine2],[DeliveryPostalCode],[DeliveryLocation]
           ,[PostalAddressLine1],[PostalAddressLine2],[PostalPostalCode],[LastEditedBy]) 
	OUTPUT deleted.*, $action, inserted.*;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

CREATE TABLE [Sales].[bulk_test] (id int);
INSERT INTO [Sales].[bulk_test] (id) VALUES (1), (2);

EXEC master..xp_cmdshell 'bcp "[WideWorldImporters].[Sales].[bulk_test]" out  "C:\projects\bulk_test.txt" -T -w -t, -S localhost'

BULK INSERT [WideWorldImporters].[Sales].[bulk_test]
				FROM 'C:\projects\bulk_test.txt'
				WITH 
					(
					BATCHSIZE = 1000, 
					DATAFILETYPE = 'widenative',
					FIELDTERMINATOR = '@eu&$1&',
					ROWTERMINATOR ='\n',
					KEEPNULLS,
					TABLOCK        
					);

SELECT COUNT(*) FROM [WideWorldImporters].[Sales].[bulk_test];