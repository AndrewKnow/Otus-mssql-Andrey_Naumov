use WarehouseForAutoTourism

--1. Категории товаров. Справочник.
CREATE TABLE Categories (
    CategoryId INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(50) NOT NULL
	CONSTRAINT CK_Categories_Name CHECK (LEN(CategoryName) > 0) -- Ограничение на пустое имя категории -- 06.01.2025
);

-- Индекс для поиска по имени -- 06.01.2025
CREATE NONCLUSTERED INDEX IX_Categories_Name ON Categories (CategoryName); 

--2. Автомобили. Марка - модель. Справочник.
CREATE TABLE Cars (
    CarModelId INT PRIMARY KEY IDENTITY(1,1),
    Brand NVARCHAR(50) NOT NULL,
    Model NVARCHAR(50) NOT NULL,
    CONSTRAINT CK_Cars_Brand CHECK (LEN(Brand) > 0), -- Ограничение на пустое имя марки -- 06.01.2025
    CONSTRAINT CK_Cars_Model CHECK (LEN(Model) > 0)   -- Ограничение на пустое имя модели -- 06.01.2025
);

-- Индекс на поля Brand и Model для быстрого поиска по марке и модели-- 06.01.2025
CREATE NONCLUSTERED INDEX IX_Cars_Brand_Model ON Cars (Brand, Model);


--3. Товары. Основной тип товара авто-тенты.
CREATE TABLE Products (
    ProductId INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100) NOT NULL,
    CategoryId INT NOT NULL,
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),  -- Ограничение на цену товара -- 06.01.2025
    Description NVARCHAR(255),
    DateAdded DATETIME2 DEFAULT GETDATE(), -- Добавлен дата внесения товара, по умолчанию будет подставлена текущая дата  -- 06.01.2025
    IsActive BIT DEFAULT 1,  -- Добавлен статус товара -- 06.01.2025
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),
	CONSTRAINT CK_Products_Name CHECK (LEN(ProductName) > 0)  -- Ограничение на пустое имя товара -- 06.01.2025
);

-- Индекс на CategoryId для быстрого поиска товаров по категориям
CREATE NONCLUSTERED INDEX IX_Products_CategoryId ON Products (CategoryId);


--4. Совместимость с автомобилем. Информация.
CREATE TABLE CarCompatibility (
	CONSTRAINT PK_CarCompatibility PRIMARY KEY (ProductId, CarModelId), --Замена на составной PK 06.01.2025
    ProductId INT NOT NULL,
    CarModelId INT NOT NULL,
    Description NVARCHAR(250),
    CONSTRAINT FK_CarCompatibility_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    CONSTRAINT FK_CarCompatibility_Cars FOREIGN KEY (CarModelId) REFERENCES Cars(CarModelId),
	CONSTRAINT CK_CarCompatibility_Description CHECK (LEN(Description) > 0)  -- Ограничение на описание совместимости -- 06.01.2025
);

-- Индекс на CarModelId для быстрого поиска совместимости по моделям автомобилей -- 06.01.2025
CREATE NONCLUSTERED INDEX IX_CarCompatibility_CarModelId ON CarCompatibility (CarModelId);

-- Создание индекса на комбинацию ProductId и CarModelId --06.01.2025
--CREATE NONCLUSTERED INDEX IX_CarCompatibility_ProductId_CarModelId ON CarCompatibility (ProductId, CarModelId);
-- 07.01.2025
--DROP INDEX [IX_CarCompatibility_ProductId_CarModelId] ON [dbo].[CarCompatibility]

--5. Аксесуары для товаров Products. Сопутсвующие товары рекомендуемые с основным товаром.
CREATE TABLE Accessories (
    AccessoriesId INT PRIMARY KEY IDENTITY(1,1),
    ProductId INT NOT NULL,
	AccessoryName NVARCHAR(100) NOT NULL,
	CategoryId INT NOT NULL,
	Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),  -- Ограничение на цену аксессуара
    Description NVARCHAR(255)
    CONSTRAINT FK_Accessories_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
	CONSTRAINT CK_Accessories_Name CHECK (LEN(AccessoryName) > 0)  -- Ограничение на пустое имя аксессуара
);

-- Индекс на ProductId для быстрого поиска аксессуаров по товарам -- 06.01.2025
CREATE NONCLUSTERED INDEX IX_Accessories_ProductId ON Accessories (ProductId);


--6. Остатки на складе. Подразумевается ввод данных по количеству на дату.
CREATE TABLE ProductsStockQuantity  (
    ProductsQuantityId INT PRIMARY KEY IDENTITY(1,1),
    ProductId INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity >= 0),  -- Ограничение на количество товаров -- 06.01.2025
    QuantitySource NVARCHAR(50) NOT NULL,  -- Источник обновления данных (например, какая-то внешняя система, инвентаризация, ERP) -- 06.01.2025
    LastUpdated DATETIME2 DEFAULT GETDATE(),  -- Дата и время последнего обновления -- 06.01.2025
    CONSTRAINT FK_ProductsStock_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);

-- Индекс на ProductId для быстрого поиска остатков по товарам -- 06.01.2025
CREATE NONCLUSTERED INDEX IX_ProductsStock_ProductId ON ProductsStockQuantity (ProductId);


--7. Остатки на складе для аксессуаров.
CREATE TABLE AccessoriesStockQuantity  (
    AccessoriesQuantityId INT PRIMARY KEY IDENTITY(1,1),
    AccessoriesId INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity >= 0),  -- Ограничение на количество товаров -- 06.01.2025
    QuantitySource NVARCHAR(50) NOT NULL,  -- Источник обновления данных (например, какая-то внешняя система, инвентаризация, ERP) -- 06.01.2025
    LastUpdated DATETIME2 DEFAULT GETDATE(),  -- Дата и время последнего обновления -- 06.01.2025
    CONSTRAINT FK_AccessoriesStocks_Accessories FOREIGN KEY (AccessoriesId) REFERENCES Accessories(AccessoriesId)
);

-- Индекс на AccessoriesId для быстрого поиска остатков по аксессуарам - 06.01.2025
CREATE NONCLUSTERED INDEX IX_AccessoriesStock_AccessoriesId ON AccessoriesStockQuantity (AccessoriesId);
