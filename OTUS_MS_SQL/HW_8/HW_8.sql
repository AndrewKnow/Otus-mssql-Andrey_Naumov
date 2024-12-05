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
	           (CustomerID,CustomerName,BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,DeliveryLocation,PostalAddressLine1,PostalAddressLine2,PostalPostalCode,LastEditedBy)
	Select 
	@NewCustomerID,N'Имя' + cast(@NewCustomerID as varchar),BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,DeliveryLocation,PostalAddressLine1,PostalAddressLine2,PostalPostalCode,LastEditedBy
	From Sales.Customers Where CustomerID = (Select max(CustomerID) From Sales.Customers);

Set @Counter = @Counter + 1; 
End

--Select top 5 * From Sales.Customers order by CustomerID desc
--Delete From Sales.Customers Where CustomerID in (Select top 5 CustomerID From Sales.Customers order by CustomerID desc)


/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

Delete From Sales.Customers Where CustomerID in (Select top 1 CustomerID From Sales.Customers order by CustomerID desc)