/*
==========================================================
AMAZONDB - MYSQL PRACTICE ASSIGNMENT
==========================================================
*/

-- Allow UPDATE / DELETE without primary key in WHERE
SET SQL_SAFE_UPDATES = 0;

-- 1. CREATE DATABASE
CREATE DATABASE IF NOT EXISTS AmazonDB;
USE AmazonDB;

-- 2. CREATE TABLES

CREATE TABLE IF NOT EXISTS Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    registered_date DATE NOT NULL,
    membership ENUM('Basic', 'Prime') DEFAULT 'Basic'
);

CREATE TABLE IF NOT EXISTS Products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    stock INT NOT NULL,
    rating DECIMAL(3, 2) DEFAULT 0.00
);

CREATE TABLE IF NOT EXISTS Orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_orders_users
        FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE IF NOT EXISTS OrderDetails (
    order_details_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    CONSTRAINT fk_orderdetails_orders
        FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    CONSTRAINT fk_orderdetails_products
        FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- 3. INSERT SAMPLE DATA
-- TRUNCATE clears the data AND resets AUTO_INCREMENT to 1,
-- so user_id / product_id / order_id always start from 1 on every re-run.
-- Foreign key checks are switched off temporarily because TRUNCATE
-- is not allowed on tables referenced by foreign keys.
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE OrderDetails;
TRUNCATE TABLE Orders;
TRUNCATE TABLE Products;
TRUNCATE TABLE Users;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO Users (name, email, registered_date, membership) VALUES
('Alice Johnson', 'alice.j@example.com', '2024-01-15', 'Prime'),
('Bob Smith', 'bob.s@example.com', '2024-02-01', 'Basic'),
('Charlie Brown', 'charlie.b@example.com', '2024-03-10', 'Prime'),
('Daisy Ridley', 'daisy.r@example.com', '2024-04-12', 'Basic');

INSERT INTO Products (name, price, category, stock, rating) VALUES
('Echo Dot', 49.99, 'Electronics', 120, 4.5),
('Kindle Paperwhite', 129.99, 'Books', 50, 4.8),
('Fire Stick', 39.99, 'Electronics', 80, 4.2),
('Yoga Mat', 19.99, 'Fitness', 200, 4.0),
('Wireless Mouse', 24.99, 'Electronics', 150, 4.3);

-- Order 1 = 2 x Echo Dot (49.99) = 99.98
INSERT INTO Orders (user_id, order_date, total_amount) VALUES
(1, '2024-05-01', 99.98),
(2, '2024-05-03', 129.99),
(1, '2024-05-04', 49.99),
(3, '2024-05-05', 24.99);

INSERT INTO OrderDetails (order_id, product_id, quantity) VALUES
(1, 1, 2),
(2, 2, 1),
(3, 1, 1),
(4, 5, 1);


-- Q1. List all customers who have made purchases of more than $80.

-- Version A: customers with at least one single order above $80
SELECT DISTINCT
    u.user_id,
    u.name,
    u.email
FROM Users AS u
INNER JOIN Orders AS o
    ON u.user_id = o.user_id
WHERE o.total_amount > 80;

-- Explanation (Version A):
-- An INNER JOIN links the Users and Orders tables using user_id.
-- The WHERE clause keeps only orders where total_amount exceeds 80.
-- DISTINCT ensures that customers with multiple qualifying orders appear only once.

-- Version B: customers whose total spending across all orders is above $80
SELECT
    u.user_id,
    u.name,
    u.email,
    SUM(o.total_amount) AS total_spent
FROM Users AS u
INNER JOIN Orders AS o
    ON u.user_id = o.user_id
GROUP BY u.user_id, u.name, u.email
HAVING SUM(o.total_amount) > 80;

-- Explanation (Version B):
-- GROUP BY combines all orders of each customer.
-- SUM(o.total_amount) gives the customer's total spending.
-- HAVING filters the grouped result to customers who spent more than 80 in total.


-- Q2. Retrieve all orders placed in the last 280 days
--     along with the customer name and email.
SELECT
    o.order_id,
    o.order_date,
    o.total_amount,
    u.name AS customer_name,
    u.email
FROM Orders AS o
INNER JOIN Users AS u
    ON o.user_id = u.user_id
WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 280 DAY)
  AND o.order_date <= CURDATE()
ORDER BY o.order_date DESC;

-- Explanation:
-- An INNER JOIN connects Orders with Users to fetch customer details.
-- DATE_SUB(CURDATE(), INTERVAL 280 DAY) calculates the date 280 days before today.
-- The WHERE filter selects orders falling between that past date and today.
-- ORDER BY sorts the records with the latest order first.
-- Note: The sample orders are dated May 2024, so if today's date is more than
-- 280 days later, this query correctly returns an empty result.


-- Q3. Find the average product price for each category.
SELECT
    category,
    ROUND(AVG(price), 2) AS average_price
FROM Products
GROUP BY category;

-- Explanation:
-- GROUP BY splits the products into groups based on category.
-- AVG(price) computes the mean price within each category.
-- ROUND(..., 2) shows the result with 2 decimal places.


-- Q4. List all customers who have purchased a product
--     from the category Electronics.
SELECT DISTINCT
    u.user_id,
    u.name,
    u.email
FROM Users AS u
INNER JOIN Orders AS o
    ON u.user_id = o.user_id
INNER JOIN OrderDetails AS od
    ON o.order_id = od.order_id
INNER JOIN Products AS p
    ON od.product_id = p.product_id
WHERE p.category = 'Electronics';

-- Explanation:
-- Joins Users, Orders, OrderDetails and Products to connect customers with purchased items.
-- The WHERE clause keeps only items from the 'Electronics' category.
-- DISTINCT lists each customer only once, however many electronics items they ordered.


-- Q5. Find the total number of products sold and the total revenue
--     generated for each product.
SELECT
    p.product_id,
    p.name AS product_name,
    SUM(od.quantity) AS total_quantity_sold,
    SUM(od.quantity * p.price) AS total_revenue
FROM Products AS p
INNER JOIN OrderDetails AS od
    ON p.product_id = od.product_id
GROUP BY p.product_id, p.name
ORDER BY total_revenue DESC;

-- Explanation:
-- INNER JOIN connects Products with OrderDetails.
-- SUM(od.quantity) calculates total units sold for each product.
-- SUM(od.quantity * p.price) computes revenue per product.
-- GROUP BY groups the results by product ID and name.
-- ORDER BY shows the highest-grossing products first.
-- Note: Revenue is based on the product's current price (before the Q6 update).


-- Q6. Update the price of all products in the Books category,
--     increasing it by 10%.
UPDATE Products
SET price = ROUND(price * 1.10, 2)
WHERE category = 'Books';

-- Check the result
SELECT product_id, name, category, price
FROM Products
WHERE category = 'Books';

-- Explanation:
-- The UPDATE statement targets the Products table.
-- SET price = price * 1.10 applies a 10% increase; ROUND keeps 2 decimals.
-- The WHERE clause limits the update to products in the 'Books' category.
-- SQL_SAFE_UPDATES = 0 (top of script) allows this update in MySQL Workbench.


-- Q7. Remove all orders that were placed before 2020.
-- Delete child records first from OrderDetails, then parent records from Orders.
DELETE od
FROM OrderDetails AS od
INNER JOIN Orders AS o
    ON od.order_id = o.order_id
WHERE o.order_date < '2020-01-01';

DELETE FROM Orders
WHERE order_date < '2020-01-01';

-- Explanation:
-- Because of the foreign key, OrderDetails rows that refer to old orders must be deleted first.
-- The second DELETE then safely removes the matching parent rows from Orders.
-- With the current sample data no rows are deleted (all orders are from 2024).


-- Q8. Fetch order details, including customer name, product name
--     and quantity, for orders placed on 2024-05-01.
SELECT
    u.name AS customer_name,
    p.name AS product_name,
    od.quantity,
    o.order_date
FROM Orders AS o
INNER JOIN Users AS u
    ON o.user_id = u.user_id
INNER JOIN OrderDetails AS od
    ON o.order_id = od.order_id
INNER JOIN Products AS p
    ON od.product_id = p.product_id
WHERE o.order_date = '2024-05-01';

-- Explanation:
-- Joins Orders, Users, OrderDetails and Products.
-- The WHERE condition keeps only orders placed on '2024-05-01'.
-- Shows the customer's name, product purchased, quantity and order date.


-- Q9. Fetch all customers and the total number of orders they have placed.
SELECT
    u.user_id,
    u.name,
    COUNT(o.order_id) AS total_orders
FROM Users AS u
LEFT JOIN Orders AS o
    ON u.user_id = o.user_id
GROUP BY u.user_id, u.name
ORDER BY u.user_id;

-- Explanation:
-- A LEFT JOIN keeps all users, even those who have never placed an order.
-- COUNT(o.order_id) counts each user's orders (0 for users with no orders, e.g. Daisy).
-- GROUP BY summarises the result per customer.


-- Q10. Retrieve the average rating for all products in the Electronics category.
SELECT
    category,
    ROUND(AVG(rating), 2) AS average_rating
FROM Products
WHERE category = 'Electronics'
GROUP BY category;

-- Explanation:
-- The WHERE clause keeps only products in the 'Electronics' category.
-- AVG(rating) calculates the mean rating of these products.
-- ROUND(..., 2) shows the result with 2 decimal places.


-- Q11. List all customers who purchased more than 1 unit of any product,
--      including the product name and total quantity purchased.
SELECT
    u.user_id,
    u.name AS customer_name,
    p.name AS product_name,
    SUM(od.quantity) AS total_quantity_purchased
FROM Users AS u
INNER JOIN Orders AS o
    ON u.user_id = o.user_id
INNER JOIN OrderDetails AS od
    ON o.order_id = od.order_id
INNER JOIN Products AS p
    ON od.product_id = p.product_id
GROUP BY
    u.user_id,
    u.name,
    p.product_id,
    p.name
HAVING SUM(od.quantity) > 1;

-- Explanation:
-- Joins Users, Orders, OrderDetails and Products.
-- GROUP BY combines results by customer and product.
-- HAVING SUM(od.quantity) > 1 returns only customers who bought more than 1 unit of that product.


-- Q12. Find the total revenue generated by each category
--      along with the category name.
SELECT
    p.category,
    SUM(od.quantity * p.price) AS total_revenue
FROM Products AS p
INNER JOIN OrderDetails AS od
    ON p.product_id = od.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Explanation:
-- Joins Products and OrderDetails to find how many units of each product were sold.
-- SUM(od.quantity * p.price) multiplies unit price by quantity to get category revenue.
-- GROUP BY combines the figures by category.
-- ORDER BY shows categories from highest to lowest revenue.
-- Note: Books revenue reflects the 10% price increase from Q6.


-- Turn safe update mode back on (good practice)
SET SQL_SAFE_UPDATES = 1;
