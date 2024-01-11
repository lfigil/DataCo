USE supply_chain_project;

CREATE TABLE `Customers` (
  `CustomerID` integer PRIMARY KEY,
  `CustomerSegment` varchar(255),
  `CustomerCity` varchar(255),
  `CustomerState` char(2),
  `CustomerCountry` varchar(255),
  `CustomerStreet` varchar(255),
  `CustomerLatitude` decimal(8,6),
  `CustomerLongitude` decimal(9,6)
);

SELECT count(*) FROM Customers;

CREATE TABLE `Orders` (
  `OrderID` integer PRIMARY KEY,
  `OrderCode` integer,
  `OrderCustomerID` integer,
  `OrderDate` Datetime,
  `OrderStatus` varchar(255),
  `OrderCity` varchar(255),
  `OrderState` varchar(255),
  `OrderCountry` varchar(255),
  `OrderRegion` varchar(255),
  `Market` varchar(255),
  `ShippingDate` Datetime,
  `ShippingMode` varchar(255),
  `DeliveryStatus` varchar(255),
  `DaysForShippingReal` integer,
  `DaysForShipmentScheduled` integer,
  `LateDeliveryRisk` tinyint,
  `Type` varchar(255)
);

CREATE TABLE `Products` (
  `ProductID` integer PRIMARY KEY,
  `ProductDepartmentID` integer,
  `ProductCategoryID` integer,
  `ProductName` varchar(255),
  `ProductPrice` decimal(10,2)
);

CREATE TABLE `Categories` (
  `CategoryID` integer PRIMARY KEY,
  `CategoryName` varchar(255)
);

CREATE TABLE `OrderItems` (
  `OrderItemID` integer PRIMARY KEY,
  `OrderID` integer,
  `OrderItemCardprodID` integer,
  `OrderItemDiscount` decimal(10,2),
  `OrderItemDiscountRate` decimal(10,2),
  `OrderItemProfitRatio` decimal(10,2),
  `OrderProfitPerOrder` decimal(10,2),
  `OrderItemQuantity` integer,
  `Sales` decimal(10,2),
  `OrderItemTotal` decimal(10,2)
);

CREATE TABLE `Department` (
  `DepartmentID` integer PRIMARY KEY,
  `DepartmentName` varchar(255)
);

ALTER TABLE `Orders` ADD FOREIGN KEY (`OrderCustomerID`) REFERENCES `Customers` (`CustomerID`);

ALTER TABLE `Products` ADD FOREIGN KEY (`ProductDepartmentID`) REFERENCES `Department` (`DepartmentID`);

ALTER TABLE `Products` ADD FOREIGN KEY (`ProductCategoryID`) REFERENCES `Categories` (`CategoryID`);

ALTER TABLE `OrderItems` ADD FOREIGN KEY (`OrderID`) REFERENCES `Orders` (`OrderID`);

ALTER TABLE `OrderItems` ADD FOREIGN KEY (`OrderItemCardprodID`) REFERENCES `Products` (`ProductID`);

-- ==================================================================================================== --
-- EDA --
--  COUNT OF UNIQUE CUSTOMERS
SELECT 
    COUNT(CustomerID)
FROM
    customers;

-- CUSTOMER SEGMENTS    
SELECT DISTINCT
    CustomerSegment
FROM
    customers;

-- CUSTOMER COUNTRY 
SELECT DISTINCT
    CustomerCountry
FROM
    customers;

-- UNIQUE CUSTOMER STATE
SELECT 
    COUNT(DISTINCT CustomerState)
FROM
    customers;

-- TOTAL ORDERS
SELECT 
    COUNT(OrderID)
FROM
    Orders;

-- DATE RANGE OF ORDERS 
SELECT 
    MIN(OrderDate), MAX(OrderDate)
FROM
    Orders;

-- COUNT OF TOTAL ORDERS BY YEAR
SELECT 
    YEAR(OrderDate) AS orders_year,
    COUNT(OrderID) AS total_orders
FROM
    Orders
GROUP BY orders_year
ORDER BY orders_year;

-- MIN AND MAX DATE OF ORDERS PLACED IN 2018 
SELECT 
    MIN(OrderDate), MAX(OrderDate)
FROM
    Orders
WHERE YEAR(OrderDate) = 2018;

-- TOTAL UNIQUE PRODUCTS
SELECT 
    COUNT(ProductID)
FROM
    Products;

 
SELECT 
    *
FROM
    category;

SELECT 
    *
FROM
    department;

-- PRODUCT PRICE OVERVIEW    
SELECT
	MIN(ProductPrice),
    MAX(ProductPrice),
    AVG(ProductPrice)
FROM
	Products;
    
SELECT
	*
FROM
	Products
ORDER BY ProductPrice asc;


SELECT COUNT(DISTINCT OrderCountry)
FROM orders;

SELECT DISTINCT OrderRegion
FROM orders;

-- ======================================== ANALYSIS =================================================
-- What is the distribution of customers across different segments (Consumer, Corporate, Home Office)?
SELECT 
    CustomerSegment,
    COUNT(CustomerSegment) AS segment_count,
    ROUND(COUNT(CustomerSegment) / (SELECT COUNT(CustomerID) FROM customers) * 100, 2) AS '%_distribution' 
FROM
    customers
GROUP BY CustomerSegment
ORDER BY segment_count;

-- Which countries and cities have the highest number of customers?
SELECT 
    CustomerCountry, COUNT(CustomerCountry) AS country_count
FROM
    Customers
GROUP BY CustomerCountry;

-- What is the distribution of sales and profit per customer?
SELECT
    OrderCustomerID AS CustomerID,
    COUNT(O.OrderCustomerID) AS OrderCount,
    SUM(OI.OrderItemQuantity) AS ItemQuantity,
    SUM(Sales) AS TotalSales,
    ROUND(AVG(OrderProfitPerOrder), 2) AS AvgProfitPerOrder
FROM
    Orders O
INNER JOIN
    OrderItems OI ON O.OrderID = OI.OrderID
GROUP BY
    OrderCustomerID
ORDER BY
    AvgProfitPerOrder DESC;

-- Returns min,max, and counts of the avg profit per order based on customers that placed ONE order   
SELECT 
    MAX(AvgProfitPerOrder),
    MIN(AvgProfitPerOrder),
    SUM(CASE
        WHEN AvgProfitPerOrder > 0 THEN 1
        ELSE 0
    END) AS CountPostiveAgvProfit,
    SUM(CASE
        WHEN AvgProfitPerOrder < 0 THEN 1
        ELSE 0
    END) AS CountNegativeAgvProfit
FROM
    (SELECT 
        OrderCustomerID AS CustomerID,
            ROUND(AVG(OrderProfitPerOrder), 2) AS AvgProfitPerOrder
    FROM
        Orders O
    INNER JOIN OrderItems OI ON O.OrderID = OI.OrderID
    GROUP BY OrderCustomerID
    HAVING COUNT(O.OrderCustomerID) = 1
    ORDER BY AvgProfitPerOrder DESC) AS subquery;


-- Returns min,max, and counts of the avg profit per order based on the number of orders placed by each customer.
SELECT 
    OrderCount,
    MAX(AvgProfitPerOrder) AS MaxAvgProfit,
    MIN(AvgProfitPerOrder) AS MinAvgProfit,
    SUM(CountPositive) AS CountPositiveAvgProfit,
    SUM(CountNegative) AS CountNegativeAvgProfit
FROM
    (SELECT 
        OrderCustomerID AS CustomerID,
        COUNT(OrderCustomerID) AS OrderCount,
        ROUND(AVG(OrderProfitPerOrder), 2) AS AvgProfitPerOrder,
        SUM(CASE WHEN OrderProfitPerOrder > 0 THEN 1 ELSE 0 END) AS CountPositive,
        SUM(CASE WHEN OrderProfitPerOrder < 0 THEN 1 ELSE 0 END) AS CountNegative
    FROM
        Orders O
    INNER JOIN OrderItems OI ON O.OrderID = OI.OrderID
    GROUP BY OrderCustomerID
    HAVING COUNT(O.OrderCustomerID) IN (
        SELECT COUNT(OrderCustomerID)
        FROM Orders OI
        INNER JOIN OrderItems O ON OI.OrderID = O.OrderID
        GROUP BY OrderCustomerID
    )) AS subquery
GROUP BY OrderCount
ORDER BY OrderCount;

-- Calculates the percentage of orders with positive, negative and no profits.
SELECT 
    SUM(CASE
        WHEN OrderProfitPerOrder > 0 THEN 1
        ELSE 0
    END) / (SELECT 
            COUNT(*)
        FROM
            orderitems) * 100 AS '%_OrdersPositiveProfits',
    SUM(CASE
        WHEN OrderProfitPerOrder < 0 THEN 1
        ELSE 0
    END) / (SELECT 
            COUNT(*)
        FROM
            orderitems) * 100 AS '%_OrdersNegativeProfits',
    SUM(CASE
        WHEN OrderProfitPerOrder = 0 THEN 1
        ELSE 0
    END) / (SELECT 
            COUNT(*)
        FROM
            orderitems) * 100 AS '%_OrdersNoProfit'
FROM
    orderitems;

-- What is the distribution of order statuses (Complete, Pending, etc.)?
SELECT OrderStatus, COUNT(OrderStatus) AS Count,
ROUND(COUNT(OrderStatus) / SUM(COUNT(OrderRegion)) OVER () * 100, 2) AS StatusPercentage
FROM Orders
GROUP BY OrderStatus
ORDER BY Count;

-- Analyzing in dept SUSPECTED_FRAUD 
SELECT
    OrderRegion,
    COUNT(OrderRegion) AS FraudCount,
    ROUND((COUNT(OrderRegion) / SUM(COUNT(OrderRegion)) OVER ()) * 100, 2) AS FraudPercentage
FROM
    Orders
WHERE
    OrderStatus = 'SUSPECTED_FRAUD'
GROUP BY
    OrderRegion
ORDER BY
    FraudCount DESC;
    
-- Outputs the times a customer is involved in suspected fraud
SELECT DISTINCT
    OrderCustomerID, COUNT(*) AS FraudCountPerCustomerID
FROM
    Orders
WHERE
    OrderStatus = 'SUSPECTED_FRAUD'
GROUP BY OrderCustomerID
ORDER BY 2 DESC;


SELECT
    C.CustomerID
FROM
    Customers C
WHERE
    NOT EXISTS (
        SELECT 1
        FROM
            Orders O
        WHERE
            O.OrderCustomerID = C.CustomerID
            AND O.OrderStatus <> 'SUSPECTED_FRAUD'
    );

-- How is the on-time delivery performance?
SELECT
	DeliveryStatus,
	COUNT(DeliveryStatus) AS Count,
    ROUND(COUNT(DeliveryStatus) / (select count(*) from orders), 2) * 100 AS StatusPercentage
FROM
	Orders
GROUP BY DeliveryStatus
ORDER BY Count;

SELECT 
    AVG(DaysForShippingReal - DaysForShipmentScheduled) AS AvgDaysLate,
    MIN(DaysForShippingReal - DaysForShipmentScheduled) AS MinDaysLate,
    MAX(DaysForShippingReal - DaysForShipmentScheduled) AS MaxDaysLate
FROM
    Orders
WHERE
    DeliveryStatus = 'Late delivery';
    

SELECT
    ShippingMode,
    COUNT(*) AS TotalOrders,
    SUM(CASE WHEN DeliveryStatus = 'Late delivery' THEN 1 ELSE 0 END) AS LateDeliveries,
    ROUND(SUM(CASE WHEN DeliveryStatus = 'Late delivery' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS LateDeliveryPercentage
FROM
    Orders
GROUP BY
    ShippingMode
ORDER BY LateDeliveryPercentage;

-- Percentage of region that have the most late deliveries
SELECT 
    OrderRegion, 
    COUNT(OrderRegion) AS RegionCount, 
    ROUND(COUNT(OrderRegion) / SUM(COUNT(OrderRegion)) OVER() * 100, 2) AS LatePercentage
FROM
    Orders
WHERE
    DeliveryStatus = 'Late delivery'
GROUP BY OrderRegion
ORDER BY 2 DESC;

-- How does the choice of shipping mode vary across different markets?
SELECT
    Market,
    ShippingMode,
    COUNT(*) AS TotalOrders
FROM
    Orders
GROUP BY
    Market, ShippingMode
ORDER BY
    Market, TotalOrders DESC;

-- Analyze the distribution of orders over time (daily, monthly, yearly).
SELECT
    DATE(OrderDate) AS OrderDay,
    COUNT(*) AS DailyOrderCount
FROM
    Orders
GROUP BY
    OrderDay
ORDER BY
    OrderDay;

SELECT
    DATE_FORMAT(OrderDate, '%Y-%m') AS OrderMonth,
    COUNT(*) AS MonthlyOrderCount
FROM
    Orders
GROUP BY
    OrderMonth
ORDER BY
    OrderMonth;

SELECT
    YEAR(OrderDate) AS OrderYear,
    COUNT(*) AS YearlyOrderCount
FROM
    Orders
GROUP BY
    OrderYear
ORDER BY
    OrderYear;


-- Identify any seasonality patterns in sales or order volume.
-- Sales overtime
SELECT YEAR(OrderDate) AS OrderYear,
MONTH(OrderDate) AS OrderMonth,
	SUM(Sales) AS TotalSales
FROM orders O
INNER JOIN orderitems OI ON O.OrderID = OI.OrderID
GROUP BY YEAR(OrderDate),  MONTH(OrderDate)
ORDER BY YEAR(OrderDate), MONTH(OrderDate);

-- Percentage of total sales by year
SELECT
	YEAR(OrderDate) AS YearSale,
    SUM(Sales) AS CurrentYearSales,
    LAG(SUM(Sales)) OVER(ORDER BY YEAR(OrderDate)) AS PreviousYearSales,
    SUM(Sales) - (LAG(SUM(Sales)) OVER(ORDER BY YEAR(OrderDate))) AS SalesDifference,
    ROUND(((SUM(Sales) - LAG(SUM(Sales)) OVER (ORDER BY YEAR(OrderDate))) / NULLIF(LAG(SUM(Sales)) OVER (ORDER BY YEAR(OrderDate)), 0)) * 100, 2) AS '%_change'
FROM orders O
INNER JOIN orderitems OI ON O.OrderID = OI.OrderID
GROUP BY YearSale
ORDER BY YearSale;

-- Percentage change of sales by year and month.
SELECT
	YEAR(OrderDate) AS YearSale,
    MONTH(OrderDate) AS MonthSale,
    SUM(Sales) AS CurrentYearSales,
    LAG(SUM(Sales)) OVER(ORDER BY YEAR(OrderDate)) AS PreviousYearSales,
    SUM(Sales) - (LAG(SUM(Sales)) OVER(ORDER BY YEAR(OrderDate),  MONTH(OrderDate))) AS SalesDifference,
    ROUND(((SUM(Sales) - LAG(SUM(Sales)) OVER (ORDER BY YEAR(OrderDate),  MONTH(OrderDate))) / NULLIF(LAG(SUM(Sales)) OVER (ORDER BY YEAR(OrderDate), MONTH(OrderDate)), 0)) * 100, 2) AS '%_change'
FROM orders O
INNER JOIN orderitems OI ON O.OrderID = OI.OrderID
GROUP BY YearSale, MonthSale
ORDER BY YearSale, MonthSale; 

-- What are the most sold products by customers across different segments (Consumer, Corporate, Home Office)?
WITH RankedProducts AS (
	SELECT
		CustomerSegment,
        ProductName,
        SUM(OrderItemQuantity) AS TotalQuantitySold,
        ROW_NUMBER() OVER(PARTITION BY CustomerSegment ORDER BY SUM(OrderItemQuantity) DESC ) AS Ranking
	FROM
	Customers C
    JOIN Orders O ON C.CustomerID = O.OrderCustomerID
    JOIN OrderItems OI ON O.OrderID = OI.OrderID
    JOIN Products P ON OI.OrderItemCardprodID = P.ProductID
GROUP BY
    CustomerSegment, ProductName
)
SELECT
	CustomerSegment,
    ProductName,
    TotalQuantitySold
FROM RankedProducts
WHERE Ranking <= 10
ORDER BY CustomerSegment, Ranking;