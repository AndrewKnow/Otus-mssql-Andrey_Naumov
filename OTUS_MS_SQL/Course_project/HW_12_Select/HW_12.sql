
--Описание/Пошаговая инструкция выполнения домашнего задания:
--Думаем какие запросы у вас будут в базе и добавляем для них индексы. Проверяем, что они используются в запросе.


-- поиск категории
CREATE NONCLUSTERED INDEX IX_Categories_Name ON Categories (CategoryName); 

-- поиск авто
CREATE NONCLUSTERED INDEX IX_Cars_Brand_Model ON Cars (Brand, Model);

-- поиск товаров
CREATE NONCLUSTERED INDEX IX_Products_CategoryId ON Products (CategoryId);

-- поиск товара совместимого с авто
CREATE NONCLUSTERED INDEX IX_CarCompatibility_CarModelId ON CarCompatibility (CarModelId);

-- поиск аксесуаров
CREATE NONCLUSTERED INDEX IX_Accessories_ProductId ON Accessories (ProductId);

-- остатки по товару
CREATE NONCLUSTERED INDEX IX_ProductsStock_ProductId ON ProductsStockQuantity (ProductId);

-- остатки аксессуаров
CREATE NONCLUSTERED INDEX IX_AccessoriesStock_AccessoriesId ON AccessoriesStockQuantity (AccessoriesId);


---------------------------------------------------------------
-- Вероятные запросы к БД (преверка использованием индексов):--
---------------------------------------------------------------


-- поиск всех аксессуаров дла товара, отобранного по авто
Select A.AccessoriesId, A.AccessoryName, A.Price, A.Description
From Accessories A
Join Products P on A.ProductId = P.ProductId
Join CarCompatibility CC on P.ProductId = CC.ProductId
Join Cars C on CC.CarModelId = C.CarModelId
Where P.ProductId = 1 and C.CarModelId = 1; 

-- поиск товаров по авто и наименованию
Select P.ProductId, P.ProductName, P.Price, P.Description
From Products P
Join CarCompatibility CC on P.ProductId = CC.ProductId
Join Cars C on CC.CarModelId = C.CarModelId
Where P.ProductName like '%тент%' and C.Brand = 'Lada'  and C.Model = 'Granta';

-- + аксессуары
Select 
    P.ProductId, 
    P.ProductName, 
    P.Price, 
    P.Description ProductDescription,
    A.AccessoriesId, 
    A.AccessoryName, 
    A.Price , 
    A.Description AccessoryDescription
From Products P
Join CarCompatibility CC on P.ProductId = CC.ProductId
Join Cars C on CC.CarModelId = C.CarModelId
Left join Accessories A on P.ProductId = A.ProductId  
Where P.ProductName LIKE '%тент%' and C.Brand = 'Lada' and C.Model = 'Granta'; 


-- Поиск аксессуаров для товара, в наименовании которого есть "тент" для авто
Select 
    P.ProductId, 
    P.ProductName, 
    P.Price ProductPrice, 
    P.Description ProductDescription,
    A.AccessoriesId, 
    A.AccessoryName, 
    A.Price AccessoryPrice, 
    A.Description AccessoryDescription
From Products P
Cross apply (
    Select 
        A.AccessoriesId, 
        A.AccessoryName, 
        A.Price, 
        A.Description
    From Accessories A
    Where A.ProductId = P.ProductId  
) A
Join CarCompatibility CC ON P.ProductId = CC.ProductId 
Join Cars C ON CC.CarModelId = C.CarModelId 
Where P.ProductName like '%тент%' 
and C.Brand = 'лада'  and C.Model = 'гранта'; 
