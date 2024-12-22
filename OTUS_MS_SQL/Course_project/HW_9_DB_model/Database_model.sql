use WarehouseForAutoTourism

--1. Категории товаров. Справочник.
CREATE TABLE Categories (
    CategoryId INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(50) NOT NULL
);

--2. Автомобили. Марка - модель. Справочник.
CREATE TABLE Cars (
    CarModelId INT PRIMARY KEY IDENTITY(1,1),
    Brand NVARCHAR(50) NOT NULL,
    Model NVARCHAR(50) NOT NULL
);

--3. Товары. Основной тип товара авто-тенты.
CREATE TABLE Products (
    ProductId INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    CategoryId INT NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Description NVARCHAR(MAX)
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId)
);


--4. Совместимость с автомобилем. Информация.
CREATE TABLE CarCompatibility (
    CompatibilityId INT PRIMARY KEY IDENTITY(1,1),
    ProductId INT NOT NULL,
    CarModelId INT NOT NULL,
    Description NVARCHAR(250),
    CONSTRAINT FK_CarCompatibility_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    CONSTRAINT FK_CarCompatibility_Cars FOREIGN KEY (CarModelId) REFERENCES Cars(CarModelId)
);

--5. Аксесуары для товаров Products. Сопутсвующие товары рекомендуемые с основным товаром.
CREATE TABLE Accessories (
    AccessoriesId INT PRIMARY KEY IDENTITY(1,1),
    ProductId INT NOT NULL,
	Name NVARCHAR(100) NOT NULL,
	CategoryId INT NOT NULL,
	Price DECIMAL(10,2) NOT NULL,
    Description NVARCHAR(MAX)
    CONSTRAINT FK_Accessories_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);

-- 6. Остатки  на складе. Подразумевается ввод данных по количеству на дату.
CREATE TABLE ProductsStockQuantity  (
    ProductsQuantityId INT PRIMARY KEY IDENTITY(1,1),
    ProductId INT NOT NULL,
	Quantity INT NOT NULL,
	QuantityOnDate DateTime NOT NULL
    CONSTRAINT FK_ProductsStock_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);

CREATE TABLE AccessoriesStockQuantity  (
    AccessoriesQuantityId INT PRIMARY KEY IDENTITY(1,1),
    AccessoriesId INT NOT NULL,
	Quantity INT NOT NULL,
	QuantityOnDate DateTime NOT NULL
    CONSTRAINT FK_AccessoriesStocks_Accessories FOREIGN KEY (AccessoriesId) REFERENCES Accessories(AccessoriesId)
);

