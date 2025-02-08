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

-- Создаем очередь
CREATE QUEUE [Queue_BrokerForReport];

-- Создаем сервис
CREATE SERVICE [Service_BrokerForReport] ON QUEUE [Queue_BrokerForReport] ([Contract_BrokerForReport]);


ALTER QUEUE [Queue_BrokerForReport]
    WITH ACTIVATION (
        STATUS = ON,
        PROCEDURE_NAME = [uspProcessMessagesFromQueue],  
        MAX_QUEUE_READERS = 1,
        EXECUTE AS OWNER
    );


--Триггер [trgSendMessageOnInsert] отправляет сообщение в очередь, процедура [uspProcessMessagesFromQueue] должна запустить обработку сообщения
--drop TRIGGER [trgSendMessageOnInsert]
CREATE TRIGGER [trgSendMessageOnInsert]
ON [dbo].[ProductsStockQuantity]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductId INT;
    DECLARE @Quantity INT;
    DECLARE @handle UNIQUEIDENTIFIER;


    SELECT @ProductId = i.ProductId, @Quantity = i.Quantity
    FROM inserted i

    IF @ProductId IS NULL
    BEGIN
        RETURN;
    END

    BEGIN DIALOG CONVERSATION @handle
        FROM SERVICE [Service_BrokerForReport]
        TO SERVICE 'Service_BrokerForReport'
        ON CONTRACT [Contract_BrokerForReport]
        WITH ENCRYPTION = OFF;

    DECLARE @message XML;
    SET @message = '<root><ProductId>' + CAST(@ProductId AS NVARCHAR(255)) + '</ProductId><Quantity>' + CAST(@Quantity AS NVARCHAR(255)) + '</Quantity></root>';

    SEND ON CONVERSATION @handle
    MESSAGE TYPE [MessageType_BrokerForReport] (@message);
    
    -- Завершаение диалога
    END CONVERSATION @handle;

END;


--Создание процедуры для обработки сообщений из очереди
--Запуск процедуры обработает сообщения из очереди, просуммирует количество товаров ReportProducts.

--drop PROCEDURE [uspProcessMessagesFromQueue]
CREATE PROCEDURE [dbo].[uspProcessMessagesFromQueue]
AS
BEGIN
    DECLARE @conversationHandle UNIQUEIDENTIFIER;
    DECLARE @messageTypeName SYSNAME;
    DECLARE @messageBody XML;

    BEGIN TRANSACTION;

    -- Ожидаем одно сообщение из очереди
    WAITFOR (
        RECEIVE TOP(1)
            @conversationHandle = conversation_handle,
            @messageTypeName = message_type_name,
            @messageBody = CAST(message_body AS XML)
        FROM [Queue_BrokerForReport]
    ), TIMEOUT 1000;

    -- Если сообщения нет, выходим
    IF @@ROWCOUNT = 0
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END

    -- Обрабатываем сообщение
    IF @messageTypeName = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
    BEGIN
        END CONVERSATION @conversationHandle;
        COMMIT TRANSACTION;
        RETURN;
    END

    DECLARE @ProductId INT;
    DECLARE @Quantity INT;

    -- Извлекаем данные из XML
    SELECT
        @ProductId = @messageBody.value('(/root/ProductId)[1]', 'INT'),
        @Quantity = @messageBody.value('(/root/Quantity)[1]', 'INT');

    -- Обновляем количество товара в таблице ReportProducts
    UPDATE [dbo].[ReportProducts]
    SET TotalQuantity = ISNULL(TotalQuantity, 0) + @Quantity
    WHERE ProductId = @ProductId;

    -- Если товар не найден, добавляем новый
    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO [dbo].[ReportProducts] (ProductId, TotalQuantity)
        VALUES (@ProductId, @Quantity);
    END

    -- Завершаем диалог
    END CONVERSATION @conversationHandle;

    COMMIT TRANSACTION;
END;
