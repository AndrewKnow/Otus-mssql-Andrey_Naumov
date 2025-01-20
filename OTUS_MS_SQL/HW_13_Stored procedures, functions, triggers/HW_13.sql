
/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

/*
Select top 1 si.CustomerID, SUM(sil.ExtendedPrice)
    From Sales.Invoices si
    join Sales.InvoiceLines sil ON si.InvoiceID = sil.InvoiceID
    Group by si.CustomerID
    order by SUM(sil.ExtendedPrice) desc

Select max(db.SumExtendedPrice)
    From (
        Select SUM(sil.ExtendedPrice) SumExtendedPrice
        From Sales.Invoices si
        join Sales.InvoiceLines sil ON si.InvoiceID = sil.InvoiceID
        Group by si.CustomerID
    ) db;

-- 149
*/

IF OBJECT_ID (N'dbo.fMaxPurchase', N'FN') IS NOT NULL DROP FUNCTION dbo.fMaxPurchase;

CREATE FUNCTION dbo.fMaxPurchase() RETURNS decimal(18, 2)
AS
BEGIN
    Declare @MaxPurchaseAmount decimal(18, 2);
    
    -- max сумма покупок среди всех клиентов
    Select @MaxPurchaseAmount = max(db.SumExtendedPrice)
    From (
        Select SUM(sil.ExtendedPrice) SumExtendedPrice
        From Sales.Invoices si
        join Sales.InvoiceLines sil ON si.InvoiceID = sil.InvoiceID
        Group by si.CustomerID
    ) db;

    return @MaxPurchaseAmount;
END;

Select dbo.fMaxPurchase()



Select dbo.fMaxPurchaseCustomerID()


/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/


IF OBJECT_ID (N'dbo.uspGetCustomerPurchaseAmount', N'P') IS NOT NULL DROP PROCEDURE dbo.uspGetCustomerPurchaseAmount;

CREATE PROCEDURE dbo.uspGetCustomerPurchaseAmount @CustomerID INT
AS
BEGIN   

    If NOT EXISTS (Select 1 from Sales.Customers Where CustomerID = @CustomerID)
    Begin
        print  N'ID не найден';
        Return;
    End

    -- сумма покупок @CustomerID
    Declare @Total decimal(18, 2);
	Select @Total = SUM(sil.ExtendedPrice)
	    From Sales.Invoices si
	    join Sales.InvoiceLines sil ON si.InvoiceID = sil.InvoiceID
		Where si.CustomerID = @CustomerID;

    -- Проверка на null
    IF @Total is null
    Begin
        set @Total = 0;
    End

	--результат
    Select @Total, @CustomerID;
END;


exec dbo.uspGetCustomerPurchaseAmount @CustomerID = 149;

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/
IF OBJECT_ID (N'dbo.fGetCustomerPurchaseAmount', N'FN') IS NOT NULL DROP FUNCTION dbo.fGetCustomerPurchaseAmount;

CREATE FUNCTION dbo.fGetCustomerPurchaseAmount (@CustomerID INT)
RETURNS DECIMAL(18, 2)
AS
BEGIN

    IF NOT EXISTS (SELECT 1 FROM Sales.Customers WHERE CustomerID = @CustomerID)
    BEGIN
        -- Если клиента нет, возвращаем 0
        RETURN 0;
    END

    -- сумма покупок @CustomerID
    Declare @Total decimal(18, 2);
	Select @Total = SUM(sil.ExtendedPrice)
	    From Sales.Invoices si
	    join Sales.InvoiceLines sil ON si.InvoiceID = sil.InvoiceID
		Where si.CustomerID = @CustomerID;

    -- Проверка на null
    IF @Total is null
    Begin
        set @Total = 0;
    End

	--результат
    RETURN @Total;
END;

SET STATISTICS TIME ON;
Select dbo.fGetCustomerPurchaseAmount(149)
SET STATISTICS TIME OFF;


SET STATISTICS TIME ON;
exec dbo.uspGetCustomerPurchaseAmount @CustomerID = 149;
SET STATISTICS TIME OFF;

-- Функция возвращает одно значение.
-- Хранимая процедура может использоваться при выполнени сложной логики

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

напишите здесь свое решение

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
