

/*Вариант 2.
Оптимизируйте запрос по БД WorldWideImporters использовать DMV, хинты и все прочее
Приложите текст запроса со статистиками по времени и операциям ввода вывода, опишите кратко ход рассуждений при оптимизации.*/

use WideWorldImporters
-- Изначальный вариант 
-- Собираем статистику с изначального варианта:
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)    
FROM Sales.Orders AS ord
    JOIN Sales.OrderLines AS det
        ON det.OrderID = ord.OrderID
    JOIN Sales.Invoices AS Inv 
        ON Inv.OrderID = ord.OrderID
    JOIN Sales.CustomerTransactions AS Trans
        ON Trans.InvoiceID = Inv.InvoiceID
    JOIN Warehouse.StockItemTransactions AS ItemTrans
        ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
    AND (Select SupplierId
         FROM Warehouse.StockItems AS It
         Where It.StockItemID = det.StockItemID) = 12
    AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
        FROM Sales.OrderLines AS Total
            Join Sales.Orders AS ordTotal
                On ordTotal.OrderID = Total.OrderID
        WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
    AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;


-- Ход рассуждений при оптимизации:

--1. Обновление статистик по исполуемым в запрсое таблицам
-- Нужно для того, чтобы оптимизатор запросов мог принимать правильные решения.
--UPDATE STATISTICS Sales.Orders;
--UPDATE STATISTICS Sales.OrderLines;
--UPDATE STATISTICS Sales.CustomerTransactions;
--UPDATE STATISTICS Sales.Invoices;
--UPDATE STATISTICS Warehouse.StockItemTransactions;

--2. Проводим реорганизация индексов 
-- Реорганизация индексов должна оптимизировать доступ к данным

--ALTER INDEX ALL ON Sales.Orders REORGANIZE;
--ALTER INDEX ALL ON Sales.OrderLines REORGANIZE;
--ALTER INDEX ALL ON Sales.Invoices REORGANIZE;
--ALTER INDEX ALL ON Sales.CustomerTransactions REORGANIZE;
--ALTER INDEX ALL ON Warehouse.StockItemTransactions REORGANIZE;
--ALTER INDEX ALL ON Warehouse.StockItems REORGANIZE;

--3. Создадим составной индекс 
--CREATE INDEX IX_StockItems_SupplierID_StockItemID
--ON Warehouse.StockItems(SupplierID, StockItemID);

--3. Смотрим наличие в плане запроса Clustered Index Scan или Table Scan

--4. Смотрим из IO наибольшие значения:
--   операций сканирования с наибольшим количеством, выявлеям OrderLines и Orders. Количество сканирований влияет на скорость выполнения запроса.
--   логических и физических операции чтения, выявлем CustomerTransactions, Invoices и Orders. Большое количество операций указывает на возможную не эффективность использования индексов
--   операций чтения LOB, выявляем OrderLines. Связано с чтением больших объемов данных.

--Улучшения:

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

--1. Создаем переменные для упрощения использования и поддержки кода
DECLARE @SupplierID INT = 12;
DECLARE @OrderTotal DECIMAL(10, 2) = 250000;

--2. Заменяем условия фильтрации WHERE по SUM(Total.UnitPrice*Total.Quantity) заказа по CustomerID на CTE
WITH OrderTotalCTE AS (
    SELECT ord.CustomerID, SUM(ordLines.UnitPrice * ordLines.Quantity) AS TotalValue
    FROM Sales.OrderLines AS ordLines
    JOIN  Sales.Orders AS ord ON ord.OrderID = ordLines.OrderID
    GROUP BY ord.CustomerID
    HAVING SUM(ordLines.UnitPrice * ordLines.Quantity) > @OrderTotal
)

SELECT  
	ord.CustomerID id_Customer, 
	ordLines.StockItemID id_StockItem,
	SUM(ordLines.UnitPrice) Total, 
	SUM(ordLines.Quantity) Quantity, 
	COUNT(ord.OrderID) Order_count    
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS ordLines ON ordLines.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = ordLines.StockItemID

--3. Замена филтра WHERE по SupplierId на JOIN
--  При использовании JOIN сервер должен учитывать индексы, статистику и другие параметры для оптимизации запроса.
JOIN Warehouse.StockItems AS It ON It.StockItemID = ordLines.StockItemID AND It.SupplierID = @SupplierID
JOIN OrderTotalCTE ON OrderTotalCTE.CustomerID = Inv.CustomerID

WHERE Inv.BillToCustomerID != ord.CustomerID AND DATEDIFF(DAY, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, ordLines.StockItemID
ORDER BY ord.CustomerID, ordLines.StockItemID

--Применим хинты. 
-- Позволяет оптимизировать план выполнения запроса для конкретных значений переменны
--		OPTION (OPTIMIZE FOR (@SupplierID = 12));
-- Указываем предпочтительный метод соединения таблиц
--		OPTION (MERGE JOIN);
-- Подсказка заставляет SQL Server следовать порядку соединений таблиц, указанному в запросе
--		OPTION (FORCE ORDER);
-- Используем до 4 процессоров
OPTION (MAXDOP 4); 

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- Применение DMV
-- Показывает статистику выполнения запросов, включая количество выполнений, среднее время выполнения, использование CPU и другие показатели
SELECT 
    qs.sql_handle,
    qs.execution_count,
    qs.total_worker_time AS CPU_Time,
    qs.total_elapsed_time / qs.execution_count AS Avg_Elapsed_Time,
    qs.total_logical_reads / qs.execution_count AS Avg_Logical_Reads,
    qs.total_physical_reads / qs.execution_count AS Avg_Physical_Reads
FROM 
    sys.dm_exec_query_stats qs
ORDER BY 
    qs.total_elapsed_time DESC;

-- Показывает планы выполнения, которые находятся в кэше SQL Server.
/*
SELECT 
    cp.plan_handle, 
    cp.cacheobjtype, 
    cp.objtype, 
    qp.query_plan
FROM 
    sys.dm_exec_cached_plans cp
CROSS APPLY 
    sys.dm_exec_query_plan(cp.plan_handle) qp
WHERE 
    cp.cacheobjtype = 'Compiled Plan'
*/