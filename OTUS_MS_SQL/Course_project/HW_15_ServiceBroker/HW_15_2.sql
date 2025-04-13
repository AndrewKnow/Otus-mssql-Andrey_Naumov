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


-- Добавление таблицы [ReportAccessories]
USE [WarehouseForAutoTourism]
GO

/****** Object:  Table [dbo].[ReportAccessories]    Script Date: 13.04.2025 18:50:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ReportAccessories](
	[AccessoriesId] [int] NOT NULL,
	[TotalQuantity] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[AccessoriesId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ReportAccessories]  WITH CHECK ADD  CONSTRAINT [FK_ReportAccessories_Accessories] FOREIGN KEY([AccessoriesId])
REFERENCES [dbo].[Accessories] ([AccessoriesId])
GO

ALTER TABLE [dbo].[ReportAccessories] CHECK CONSTRAINT [FK_ReportAccessories_Accessories]
GO





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

-- Доработка процедуры
USE [WarehouseForAutoTourism]
GO

/****** Object:  StoredProcedure [dbo].[uspProcessMessagesFromQueue]    Script Date: 13.04.2025 18:40:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--drop PROCEDURE [uspProcessMessagesFromQueue]
ALTER PROCEDURE [dbo].[uspProcessMessagesFromQueue]
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

    -- Если тип сообщения - EndDialog, завершить диалог
    IF @messageTypeName = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
    BEGIN
        END CONVERSATION @conversationHandle;
        COMMIT TRANSACTION;
        RETURN;
    END

    DECLARE @ProductId INT;
    DECLARE @Quantity INT;
    DECLARE @AccessoriesId INT;

    -- Извлекаем данные из XML
    -- Для обработки сообщения для разных таблиц, определим, какие поля извлекаем
    IF @messageBody.exist('/root/ProductId') = 1
    BEGIN
        -- Обрабатываем товар (для ReportProducts)
        SET @ProductId = @messageBody.value('(/root/ProductId)[1]', 'INT');
        SET @Quantity = @messageBody.value('(/root/Quantity)[1]', 'INT');

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
    END
    ELSE IF @messageBody.exist('/root/AccessoriesId') = 1
    BEGIN
        -- Обрабатываем аксессуар (для ReportAccessories)
        SET @AccessoriesId = @messageBody.value('(/root/AccessoriesId)[1]', 'INT');
        SET @Quantity = @messageBody.value('(/root/Quantity)[1]', 'INT');

        -- Обновляем количество аксессуаров в таблице ReportAccessories
        UPDATE [dbo].[ReportAccessories]
        SET TotalQuantity = ISNULL(TotalQuantity, 0) + @Quantity
        WHERE AccessoriesId = @AccessoriesId;

        -- Если аксессуар не найден, добавляем новый
        IF @@ROWCOUNT = 0
        BEGIN
            INSERT INTO [dbo].[ReportAccessories] (AccessoriesId, TotalQuantity)
            VALUES (@AccessoriesId, @Quantity);
        END
    END

    -- Завершаем диалог
    END CONVERSATION @conversationHandle;

    COMMIT TRANSACTION;
END;


-- создание триггеров на таблице
USE [WarehouseForAutoTourism]
GO

/****** Object:  Trigger [dbo].[trgSendMessageOnInsertAccessories]    Script Date: 13.04.2025 18:47:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Триггер [trgSendMessageOnInsert] отправляет сообщение в очередь, процедура [uspProcessMessagesFromQueue] должна запустить обработку сообщения
--drop TRIGGER [trgSendMessageOnInsert]
CREATE TRIGGER [dbo].[trgSendMessageOnInsertAccessories]
ON [dbo].[AccessoriesStockQuantity]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductId INT;
    DECLARE @Quantity INT;
    DECLARE @handle UNIQUEIDENTIFIER;


    SELECT @ProductId = i.AccessoriesId, @Quantity = i.Quantity
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
    SET @message = '<root><AccessoriesId>' + CAST(@ProductId AS NVARCHAR(255)) + '</AccessoriesId><Quantity>' + CAST(@Quantity AS NVARCHAR(255)) + '</Quantity></root>';

    SEND ON CONVERSATION @handle
    MESSAGE TYPE [MessageType_BrokerForReport] (@message);
    
    -- Завершаение диалога
    END CONVERSATION @handle;

END;

GO

ALTER TABLE [dbo].[AccessoriesStockQuantity] ENABLE TRIGGER [trgSendMessageOnInsertAccessories]
GO


USE [WarehouseForAutoTourism]
GO

/****** Object:  Trigger [dbo].[trgSendMessageOnUpdateAccessories]    Script Date: 13.04.2025 18:47:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--Триггер [trgSendMessageOnInsert] отправляет сообщение в очередь, процедура [uspProcessMessagesFromQueue] должна запустить обработку сообщения
--drop TRIGGER [trgSendMessageOnInsert]
CREATE TRIGGER [dbo].[trgSendMessageOnUpdateAccessories]
ON [dbo].[AccessoriesStockQuantity]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductId INT;
    DECLARE @Quantity INT;
    DECLARE @handle UNIQUEIDENTIFIER;


    SELECT @ProductId = i.AccessoriesId, @Quantity = i.Quantity
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
    SET @message = '<root><AccessoriesId>' + CAST(@ProductId AS NVARCHAR(255)) + '</AccessoriesId><Quantity>' + CAST(@Quantity AS NVARCHAR(255)) + '</Quantity></root>';

    SEND ON CONVERSATION @handle
    MESSAGE TYPE [MessageType_BrokerForReport] (@message);
    
    -- Завершаение диалога
    END CONVERSATION @handle;

END;

GO

ALTER TABLE [dbo].[AccessoriesStockQuantity] ENABLE TRIGGER [trgSendMessageOnUpdateAccessories]
GO

