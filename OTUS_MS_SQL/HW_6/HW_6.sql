﻿USE WideWorldImporters

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
	convert(VARCHAR(10), a.InvoiceDate, 104) [Дата]
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
Order by Convert(DATE,[Дата])

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



/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

;With cteCustomers as (
Select distinct
b.CustomerID,
b.CustomerName,
c.StockItemID,
c.UnitPrice,
a.InvoiceDate
From Sales.Invoices a
Join Sales.Customers b on b.CustomerID = a.CustomerID 
Join Sales.InvoiceLines c on c.InvoiceID = a.InvoiceID)

Select 
a.CustomerID,
a.CustomerName,
TopUnitPrice.StockItemID,
TopUnitPrice.UnitPrice,
TopUnitPrice.InvoiceDate
From Sales.Customers a
CROSS APPLY (
	select top 2 * From cteCustomers 
	Where CustomerID = a.CustomerID
	) TopUnitPrice
Order by TopUnitPrice.CustomerID, TopUnitPrice.UnitPrice desc



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