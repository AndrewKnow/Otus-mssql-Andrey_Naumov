
-- Задача:
-- Создайте очередь для формирования отчетов
-- складывайте готовый отчет в новую таблицу

USE WarehouseForAutoTourism;

-- Таблица для формирования отчета
CREATE TABLE [dbo].[ReportProducts] (
    [ProductId] INT NOT NULL,
    [TotalQuantity] INT NOT NULL,
    PRIMARY KEY ([ProductId]),
    CONSTRAINT FK_ReportProducts_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
)

---------------------------------------------------------------------------------------------------------------------
-----------------------------------Создание службы Service Broker----------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- Проверка состояния Service Broker
Select is_broker_enabled FROM sys.databases where name = 'WarehouseForAutoTourism';
SELECT *  FROM sys.service_queues 

--ALTER DATABASE WarehouseForAutoTourism SET DISABLE_BROKER WITH ROLLBACK IMMEDIATE;	
ALTER DATABASE WarehouseForAutoTourism SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE;

-- Создаем тип сообщения
CREATE MESSAGE TYPE [MessageType_BrokerForReport] VALIDATION = WELL_FORMED_XML;

-- Создаем контракт
CREATE CONTRACT [Contract_BrokerForReport] (
    [MessageType_BrokerForReport] SENT BY INITIATOR
);

-- Создаем Queue
CREATE QUEUE [Queue_BrokerForReport];

-- Создаем Service
CREATE SERVICE [Service_BrokerForReport] ON QUEUE [Queue_BrokerForReport] ([Contract_BrokerForReport]);


--ALTER QUEUE [Queue_BrokerForReport]
--    WITH ACTIVATION (
--        STATUS = ON,
--        PROCEDURE_NAME = [uspSendMessageToQueue],  
--        MAX_QUEUE_READERS = 1,
--        EXECUTE AS OWNER
--    );

--Процедура отправляет сообщение в очередь с данными о новом количестве товара.

CREATE PROCEDURE [dbo].[uspSendMessageToQueue]
    @ProductId INT,
    @Quantity INT
AS
BEGIN
    DECLARE @handle UNIQUEIDENTIFIER;
    BEGIN DIALOG CONVERSATION @handle
        FROM SERVICE [Service_BrokerForReport]
        TO SERVICE 'Service_BrokerForReport'
        ON CONTRACT [Contract_BrokerForReport]
        WITH ENCRYPTION = OFF;
    
    DECLARE @message XML;
    SET @message = '<root><ProductId>' + CAST(@ProductId AS NVARCHAR(255)) + '</ProductId><Quantity>' + CAST(@Quantity AS NVARCHAR(255)) + '</Quantity></root>';
    
    SEND ON CONVERSATION @handle
    MESSAGE TYPE [MessageType_BrokerForReport] (@message);
END


--Триггер [trgSendMessageOnInsert] вызывает процедуру [uspSendMessageToQueue] отправки сообщения в очередь при появлении новой записи в таблице ProductsStockQuantity.
--drop TRIGGER [trgSendMessageOnInsert]
CREATE TRIGGER [trgSendMessageOnInsert]
ON [dbo].[ProductsStockQuantity]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductId INT;
    DECLARE @Quantity INT;

    SELECT @ProductId = i.ProductId, @Quantity = i.Quantity
    FROM inserted i;

    EXEC [dbo].[uspSendMessageToQueue] @ProductId, @Quantity;
END


--Создание процедуры для обработки сообщений из очереди
--Запуск процедуры обработает сообщения из очереди, просуммирует количество товаров ReportProducts.

--drop PROCEDURE [uspProcessMessagesFromQueue]
CREATE PROCEDURE [dbo].[uspProcessMessagesFromQueue]
AS
BEGIN
    DECLARE @conversationHandle UNIQUEIDENTIFIER;
    DECLARE @messageTypeName SYSNAME;
    DECLARE @messageBody XML;

    WHILE (1=1)
    BEGIN
        BEGIN TRANSACTION;
        
        WAITFOR (
            RECEIVE TOP(1)
                @conversationHandle = conversation_handle,
                @messageTypeName = message_type_name,
                @messageBody = CAST(message_body AS XML)
            FROM [Queue_BrokerForReport]
        ), TIMEOUT 1000;

        IF @@ROWCOUNT = 0
        BEGIN
            COMMIT TRANSACTION;
            BREAK;
        END

        IF @messageTypeName = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
        BEGIN
            END CONVERSATION @conversationHandle;
            COMMIT TRANSACTION;
            CONTINUE;
        END

        DECLARE @ProductId INT;
        DECLARE @Quantity INT;

        SELECT
            @ProductId = @messageBody.value('(/root/ProductId)[1]', 'INT'),
            @Quantity = @messageBody.value('(/root/Quantity)[1]', 'INT');

        Update [dbo].[ReportProducts]
        Set TotalQuantity = ISNULL(TotalQuantity, 0) + @Quantity
        Where ProductId = @ProductId;

        IF @@ROWCOUNT = 0
        BEGIN
            Insert into [dbo].[ReportProducts] (ProductId, TotalQuantity)
            values (@ProductId, @Quantity);
        END

        END CONVERSATION @conversationHandle;

        COMMIT TRANSACTION;
    END
END
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------Проверка----------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------

-- Вставка записи в [ProductsStockQuantity], в которой должен отработать триггер [trgSendMessageOnInsert],
-- запускающий отправку сообщения в очередь через процедуру [uspSendMessageToQueue]
INSERT INTO [dbo].[ProductsStockQuantity]
           ([ProductId]
           ,[Quantity]
           ,[QuantitySource]
           ,[LastUpdated])
     VALUES
           (2
           ,500
           ,'BrokerForReport'
           ,'2025-02-01')
GO


Select * From [dbo].[ProductsStockQuantity]

--список диалогов
SELECT conversation_handle, is_initiator, s.name as 'local service', 
far_service, sc.name 'contract', ce.state_desc
FROM sys.conversation_endpoints ce --представление диалогов(постепенно очищается) чтобы ее не переполнять - --НЕЛЬЗЯ ЗАВЕРШАТЬ ДИАЛОГ ДО ОТПРАВКИ ПЕРВОГО СООБЩЕНИЯ
LEFT JOIN sys.services s
ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;

-- обработка сообщений из очереди
EXEC [uspProcessMessagesFromQueue]

Select * From [ReportProducts]

--EXEC [uspSendMessageToQueue] 1, 2

-- поиск количества остатков товаров на определенные даты

Declare @ColumnsDateList nvarchar(max), @sql nvarchar(max);

-- Уникальные даты для столбцов
Select @ColumnsDateList = STRING_AGG(QUOTENAME(convert(varchar(10), LastUpdated, 120)), ', ')
From (Select distinct convert(varchar(10), LastUpdated, 120) AS LastUpdated
      From ProductsStockQuantity) AS DateList;

Set @SQL = '
Select ProductName, QuantitySource, ' + @ColumnsDateList + '
From 
(
    Select 
        P.ProductName,
        PSQ.QuantitySource,
        convert(varchar(10), PSQ.LastUpdated, 120) AS StockDate,  -- конвертируем дату для использования в pivot
        PSQ.Quantity
    From ProductsStockQuantity PSQ
    Join Products P ON PSQ.ProductId = P.ProductId
) AS SourceTable
pivot 
(
    sum(Quantity)  -- подсчет остатков на определенную дату @ColumnsDateList
    For StockDate in (' + @ColumnsDateList + ')  
) AS PivotTable
Order by ProductName, QuantitySource;
';

exec sp_executesql @SQL;







---------------Закрытие диалога------------------
DECLARE @conversationHandle UNIQUEIDENTIFIER;
-- Получаем первый разговор из очереди
WAITFOR (
    RECEIVE TOP(1)
        @conversationHandle = conversation_handle
    FROM [Queue_BrokerForReport]
), TIMEOUT 1000;

IF @conversationHandle IS NOT NULL
BEGIN
    -- Закрываем диалог
    END CONVERSATION @conversationHandle;
END


