
--Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года
--(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
--Нарастающий итог должен быть без оконной функции.
set statistics time ON;
set statistics io ON;

;With cte as (
Select year(b.InvoiceDate) год, month(b.InvoiceDate) месяц, sum(a.ExtendedPrice) продажи 
From Sales.InvoiceLines a Inner join Sales.Invoices b ON a.InvoiceID = b.InvoiceID
Where b.InvoiceDate >= '2015-01-01' 
Group by year(b.InvoiceDate), month(b.InvoiceDate))

Select 
cte.год,
cte.месяц,
cte.продажи,  
(Select sum(продажи) FROM cte cte2 WHERE cte2.год < cte.год or (cte2.год = cte.год AND cte2.месяц <= cte.месяц)) [нарастающий итог]  
From cte
Order by cte.год, cte.месяц;

--Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.

Select 
db.год,
db.месяц,
db.продажи,
sum(db.продажи) over (Order by db.год,db.месяц) [нарастающий итог] 
From 
	(
		Select year(b.InvoiceDate) год, month(b.InvoiceDate) месяц, sum(a.ExtendedPrice) продажи 
		From Sales.InvoiceLines a Inner join Sales.Invoices b ON a.InvoiceID = b.InvoiceID
		Where b.InvoiceDate >= '2015-01-01' 
		Group by year(b.InvoiceDate), month(b.InvoiceDate)
	) db
Order by db.год, db.месяц;

set statistics time OFF;
set statistics io OFF;
--Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
--Время ЦП без оконной функции = 1562 мс, затраченное время = 9813 мс. > Время ЦП с помощью оконной функции = 92 мс, затраченное время = 38 мс.