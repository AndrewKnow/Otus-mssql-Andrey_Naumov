USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

;With cteCustomerInvoices as
(Select 
	count(a.InvoiceID) [Кол-во], 
	substring(с.CustomerName, charindex('(', с.CustomerName) + 1, charindex(')', с.CustomerName) - charindex('(', с.CustomerName) - 1) [Название], 
	convert(varchar(10), dateadd(month, datediff(month, 0, a.InvoiceDate), 0), 104) [Дата]
From Sales.Invoices a Join Sales.Customers с ON a.CustomerID = с.CustomerID
Where a.CustomerID between 2 and 6
Group by 
	substring(с.CustomerName, charindex('(', с.CustomerName) + 1, charindex(')', с.CustomerName) - charindex('(', с.CustomerName) - 1), 
	convert(varchar(10), dateadd(month, datediff(month, 0, a.InvoiceDate), 0), 104))

Select *
From cteCustomerInvoices
Pivot
(
    sum([Кол-во])
    for [Название] IN ([Sylvanite, MT],	[Peeples Valley, AZ], [Medicine Lodge, KS],	[Gasport, NY], [Jessie, ND])
) pivotTbl
Order by  convert(DATE, [Дата], 104) 

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
Select 
CustomerName,
DeliveryAddress.AddressLine
From 
    Sales.Customers
Cross apply
    (values 
        (DeliveryAddressLine1),
        (DeliveryAddressLine2)
    ) DeliveryAddress(AddressLine)
Where 
    CustomerName like '%Tailspin Toys%'
    and (DeliveryAddressLine1 is not null or DeliveryAddressLine2 is not null);


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/
Select 
CountryID, 
CountryName, 
CountryCode.Code
From 
    Application.Countries
Cross apply
    (values 
        (IsoAlpha3Code),
        (cast(IsoNumericCode as nvarchar))
    ) CountryCode(Code)
Order by CountryID, CountryCode.Code;


Select 
    CountryID, 
    CountryName, 
    Code
From 
    (Select 
	CountryID, 
	CountryName, 
	cast(IsoAlpha3Code as nvarchar) IsoAlpha3Code, 
	cast(IsoNumericCode as nvarchar) 
	IsoNumericCode From Application.Countries) tbl
Unpivot
    (Code For CountryCode in (IsoAlpha3Code, IsoNumericCode)) unpivotTbl
Order by CountryID, Code;


/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/



Select 
cus.CustomerID,
cus.CustomerName,
TopUnitPrice.StockItemID,
TopUnitPrice.Description,
TopUnitPrice.UnitPrice,
TopUnitPrice.дата
From Sales.Customers cus
Cross apply (
	Select top 2 with ties
	b.CustomerID,
	b.CustomerName,
	c.StockItemID,
	c.Description,
	c.UnitPrice,
	max(a.InvoiceDate) дата
	From Sales.Invoices a
	Join Sales.Customers b on b.CustomerID = a.CustomerID 
	Join Sales.InvoiceLines c on c.InvoiceID = a.InvoiceID
	Where b.CustomerID = cus.CustomerID
	Group by b.CustomerID,b.CustomerName,c.StockItemID,c.Description,c.UnitPrice
	Order by c.UnitPrice desc
) TopUnitPrice
Order by cus.CustomerID





--Select 
--cus.CustomerID,
--cus.CustomerName,
--TopUnitPrice.StockItemID,
--TopUnitPrice.UnitPrice,
--(Select max(i.InvoiceDate) From Sales.Invoices i
--	Join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
--	Where 
--	il.StockItemID = TopUnitPrice.StockItemID and 
--	i.CustomerID = cus.CustomerID) дата
--From Sales.Customers cus
--Cross apply (
--	Select distinct top 2
--	il.StockItemID,
--	il.UnitPrice
--	From Sales.Invoices i
--	Join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
--	Where i.CustomerID = cus.CustomerID
--	Order by il.UnitPrice desc, il.StockItemID desc
--) TopUnitPrice
--Order by cus.CustomerID, TopUnitPrice.UnitPrice desc



--Select 
--cus.CustomerID,
--cus.CustomerName,
--TopUnitPrice.StockItemID,
--TopUnitPrice.UnitPrice,
--TopUnitPrice.дата
--From Sales.Customers cus
--Cross apply (
--	Select distinct top 2
--	b.CustomerID,
--	b.CustomerName,
--	c.StockItemID,
--	c.UnitPrice,
--	max(a.InvoiceDate) дата
--	From Sales.Invoices a
--	Join Sales.Customers b on b.CustomerID = a.CustomerID 
--	Join Sales.InvoiceLines c on c.InvoiceID = a.InvoiceID
--	Where b.CustomerID = cus.CustomerID
--	Group by b.CustomerID,b.CustomerName,c.StockItemID,c.UnitPrice
--	Order by c.UnitPrice desc
--) TopUnitPrice
--Order by cus.CustomerID





























--Для проверки задание 1
/*
Select a.CustomerID, count(a.InvoiceID) [Кол-во]
From Sales.Invoices a  Join Sales.Customers с ON a.CustomerID = с.CustomerID
Where a.CustomerID between 2 and 6
group by a.CustomerID

;With cteCustomerInvoices as
(Select 
	count(a.InvoiceID) [Кол-во], 
	substring(с.CustomerName, charindex('(', с.CustomerName) + 1, charindex(')', с.CustomerName) - charindex('(', с.CustomerName) - 1) [Название]
From Sales.Invoices a Join Sales.Customers с ON a.CustomerID = с.CustomerID
Where a.CustomerID between 2 and 6
Group by 
	substring(с.CustomerName, charindex('(', с.CustomerName) + 1, charindex(')', с.CustomerName) - charindex('(', с.CustomerName) - 1), 
	convert(VARCHAR(10), a.InvoiceDate, 104))

Select *
From cteCustomerInvoices
Pivot
(
	sum([Кол-во])
	for [Название] IN ([Sylvanite, MT],	[Peeples Valley, AZ], [Medicine Lodge, KS],	[Gasport, NY], [Jessie, ND])
) pivotTbl
*/


--Проверка задание 2
/*
Select CustomerName, DeliveryAddressLine1 From Sales.Customers
Where CustomerName like 'Tailspin Toys%' and DeliveryAddressLine1 is not null
union all
Select CustomerName, DeliveryAddressLine2 From Sales.Customers
Where CustomerName like 'Tailspin Toys%' and DeliveryAddressLine2 is not null
Order by CustomerName
*/