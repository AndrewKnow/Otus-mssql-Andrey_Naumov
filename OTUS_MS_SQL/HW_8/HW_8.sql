USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

Declare @Counter int = 1;
While @Counter <= 5
Begin

--Уникальным должен быть CustomerID и CustomerName
	Declare @NewCustomerID int;
	
	Select @NewCustomerID = max(CustomerID) + 1 From Sales.Customers;
	
	Insert into Sales.Customers
	(CustomerID,CustomerName,BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,DeliveryCityID,PostalCityID,
	CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,
	DeliveryAddressLine2,DeliveryPostalCode,DeliveryLocation,PostalAddressLine1,PostalAddressLine2,PostalPostalCode,LastEditedBy)
	Select 
	@NewCustomerID,N'Имя' + cast(@NewCustomerID as varchar),BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,
	DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,FaxNumber,DeliveryRun,RunPosition,
	WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,DeliveryLocation,PostalAddressLine1,PostalAddressLine2,PostalPostalCode,LastEditedBy
	From Sales.Customers Where CustomerID = (Select max(CustomerID) From Sales.Customers);

Set @Counter = @Counter + 1; 
End
--Просмотр добавленных
--Select top 5 * From Sales.Customers order by CustomerID desc

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

Delete From Sales.Customers Where CustomerID in (Select top 1 CustomerID From Sales.Customers order by CustomerID desc)

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

Update Sales.Customers Set CustomerName = N'Имя_Update' Where CustomerID in (Select top 1 CustomerID From Sales.Customers order by CustomerID desc) 

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/
--Создание copy Sales.Customers_copy п.1
	Drop table if EXISTS Sales.Customers_copy;
	Select * Into Sales.Customers_copy From Sales.Customers;
	--Select count(*) From Sales.Customers_copy; 
	--Select count(*) From Sales.Customers; 

--Удаление из Sales.Customers_copy п.2
	--Delete From Sales.Customers_copy Where CustomerID in (Select top 1 CustomerID From Sales.Customers_copy order by CustomerID desc)
--Обновление Sales.Customers_copy п.3
	--Update Sales.Customers_copy Set CustomerName = N'Имя_Update' Where CustomerID in (Select top 1 CustomerID From Sales.Customers_copy order by CustomerID desc) 
	--Select top 3 * From Sales.Customers_copy order by CustomerID desc; 
	--Select top 3 * From Sales.Customers order by CustomerID desc; 


Merge into Sales.Customers_copy as target
Using Sales.Customers as source
On target.CustomerID = source.CustomerID

When MATCHED Then
	-- 'Имя_Update'  должно стать 'Имя1065' для CustomerID = 1065
    Update SET target.CustomerName = source.CustomerName

When NOT MATCHED by target Then
	-- Добавление записи CustomerID = 1066
	Insert 
	(CustomerID,CustomerName,
	BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,
	DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,
	FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,DeliveryLocation,PostalAddressLine1,
	PostalAddressLine2,PostalPostalCode,LastEditedBy,ValidFrom,ValidTo)
	values 
	(source.CustomerID,source.CustomerName,
	source.BillToCustomerID,source.CustomerCategoryID,source.BuyingGroupID,source.PrimaryContactPersonID,source.AlternateContactPersonID,
	source.DeliveryMethodID,source.DeliveryCityID,source.PostalCityID,source.CreditLimit,source.AccountOpenedDate,source.StandardDiscountPercentage,
	source.IsStatementSent,IsOnCreditHold,PaymentDays,source.PhoneNumber,source.FaxNumber,source.DeliveryRun,source.RunPosition,WebsiteURL,source.DeliveryAddressLine1,
	source.DeliveryAddressLine2,source.DeliveryPostalCode,source.DeliveryLocation,source.PostalAddressLine1,source.PostalAddressLine2,source.PostalPostalCode,source.LastEditedBy,
	source.ValidFrom,source.ValidTo);


/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/
--Очистка Sales.Customers_copy для bulk insert
	--Delete From Sales.Customers_copy 

-- выгрузит данные через bcp out
	Declare @out varchar(250);
	set @out = N'bcp WideWorldImporters.Sales.Customers OUT "C:\BCP.txt" -T -c -S ' + @@SERVERNAME;
	Print @out;
	
	Exec master..xp_cmdshell @out


	--output
	--	NULL
	--	Начато копирование...
	--	SQLState = S1000, NativeError = 0
	--	Error = [Microsoft][ODBC Driver 17 for SQL Server]Warning: BCP import with a format file will convert empty strings in delimited columns to NULL.
	--	NULL
	--	Скопировано строк: 668.
	--	Размер сетевого пакета (в байтах): 4096
	--	Время (мс) Всего     : 15     В среднем : (44533.33 строк в секунду.)
	--	NULL

-- загрузить через bulk insert	
	Declare @in varchar(250);
	set @in = N'bcp WideWorldImporters.Sales.Customers_copy IN "C:\BCP.txt" -T -c -S ' + @@SERVERNAME;
	
	Exec master..xp_cmdshell @in;
	
	--SELECT * FROM WideWorldImporters.Sales.Customers_copy;

	--output
	--	NULL
	--	Начато копирование...
	--	NULL
	--	Скопировано строк: 668.
	--	Размер сетевого пакета (в байтах): 4096
	--	Время (мс) Всего     : 1      В среднем : (668000.00 строк в секунду.)
	--	NULL














-- 

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

/*
	Insert into Sales.Customers
	           (CustomerID,CustomerName,BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,DeliveryLocation,PostalAddressLine1,PostalAddressLine2,PostalPostalCode,LastEditedBy)
	Select Next value for Sequences.CustomerID,N'Имя' + cast(CustomerID as varchar),BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,DeliveryLocation,PostalAddressLine1,PostalAddressLine2,PostalPostalCode,LastEditedBy
	From Sales.Customers Where CustomerID = (Select max(CustomerID) From Sales.Customers);
*/