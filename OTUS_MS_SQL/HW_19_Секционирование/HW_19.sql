--Цель:
--В этом ДЗ вы выберете таблицу-кандидат для секционирования и научитесь добавлять партиционирование.

--Описание/Пошаговая инструкция выполнения домашнего задания:
--делаем анализ базы данных из первого модуля, выбираем таблицу и делаем ее секционирование,
--с переносом данных по секциям (партициям) - исходя из того, что таблица большая, 
--пишем скрипты миграции в секционированную таблицу

use WideWorldImporters
-- Выбрана таблица:
-- [Warehouse].[StockItemTransactions]
Select min(TransactionOccurredWhen) as от, max(TransactionOccurredWhen) as до From  [Warehouse].[StockItemTransactions]


-- Создание новой файловой группы
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [PARTITION_FILEGROUP]
GO

ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'HW_19', FILENAME =  N'C:\Program Files\Microsoft SQL Server\MSSQL16.OTUSSQL\MSSQL\DATA\PARTITION_FILEGROUP.ndf' , 
SIZE = 1097152KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PARTITION_FILEGROUP]
GO

--Создание функциии для определения секций
CREATE PARTITION FUNCTION [PF_TransactionOccurredWhen](datetime2)
AS RANGE RIGHT FOR VALUES ('2013-01-01', '2014-01-01', '2015-01-01', '2016-01-01');

-- Создание схемы, расположение секций
CREATE PARTITION SCHEME [PS_TransactionOccurredWhen] 
AS PARTITION [PF_TransactionOccurredWhen] ALL TO ([PARTITION_FILEGROUP])

-- Создание таблицы
CREATE TABLE StockItemTransactionPartitioned (
    StockItemTransactionID INT NOT NULL,
    StockItemID INT NOT NULL,
    TransactionTypeID INT NOT NULL,
    CustomerID INT NULL,
    InvoiceID INT NULL,
    SupplierID INT NULL,
    PurchaseOrderID INT NULL,
    TransactionOccurredWhen DATETIME2(7) NOT NULL,
    Quantity DECIMAL(18, 3) NOT NULL,
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL
) 
ON [PS_TransactionOccurredWhen](TransactionOccurredWhen);

Declare @out varchar(250);
set @out = N'bcp WideWorldImporters.Warehouse.StockItemTransactions OUT "C:\BCP.txt" -T -c -S ' + @@SERVERNAME;
Print @out;
Exec master..xp_cmdshell @out

Declare @in varchar(250);
set @in = N'bcp WideWorldImporters.dbo.StockItemTransactionPartitioned IN "C:\BCP.txt" -T -c -S ' + @@SERVERNAME;
Exec master..xp_cmdshell @in;
	
-- Индекс
CREATE INDEX IX_StockItemTransactionPartitioned_TransactionOccurredWhen
ON StockItemTransactionPartitioned (TransactionOccurredWhen);


-- Вывод данных из секции
SELECT 
    *,
    $PARTITION.PF_TransactionOccurredWhen(TransactionOccurredWhen) AS Секция
FROM 
    StockItemTransactionPartitioned
WHERE 
    $PARTITION.PF_TransactionOccurredWhen(TransactionOccurredWhen) = 5
ORDER BY 
    TransactionOccurredWhen;

-- Вывод по количеству строк
SELECT  $PARTITION.[PF_TransactionOccurredWhen](TransactionOccurredWhen) AS Секция
		,COUNT(*) AS [Количество строк]
		,MIN(TransactionOccurredWhen) AS [От]
		,MAX(TransactionOccurredWhen) AS [До]
FROM StockItemTransactionPartitioned
GROUP BY $PARTITION.[PF_TransactionOccurredWhen](TransactionOccurredWhen) 
ORDER BY Секция ;  
