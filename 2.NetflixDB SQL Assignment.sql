/*
======================================
NETFLIXDB - MYSQL PRACTICE ASSIGNMENT 
======================================
*/

-- Allow UPDATE / DELETE without primary key in WHERE (MySQL Workbench safe mode)
SET SQL_SAFE_UPDATES = 0;

-- 1. CREATE DATABASE
CREATE DATABASE IF NOT EXISTS NetflixDB;
USE NetflixDB;

-- 2. CREATE TABLES

CREATE TABLE IF NOT EXISTS Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    registration_date DATE NOT NULL,
    plan ENUM('Basic', 'Standard', 'Premium') DEFAULT 'Basic'
);

CREATE TABLE IF NOT EXISTS Movies (
    movie_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200) NOT NULL,
    genre VARCHAR(100) NOT NULL,
    release_year YEAR NOT NULL,
    rating DECIMAL(3, 1) NOT NULL
);

CREATE TABLE IF NOT EXISTS WatchHistory (
    watch_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    movie_id INT,
    watched_date DATE NOT NULL,
    completion_percentage INT CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (movie_id) REFERENCES Movies(movie_id)
);

CREATE TABLE IF NOT EXISTS Reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    movie_id INT,
    user_id INT,
    review_text TEXT,
    rating DECIMAL(2, 1) CHECK (rating >= 0 AND rating <= 5),
    review_date DATE NOT NULL,
    FOREIGN KEY (movie_id) REFERENCES Movies(movie_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- 3. INSERT SAMPLE DATA
-- TRUNCATE clears old data AND resets AUTO_INCREMENT to 1, so the script can be re-run.
-- Foreign key checks are switched off temporarily because TRUNCATE
-- is not allowed on tables referenced by foreign keys.
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE Reviews;
TRUNCATE TABLE WatchHistory;
TRUNCATE TABLE Movies;
TRUNCATE TABLE Users;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO Users (name, email, registration_date, plan) VALUES
('John Doe', 'john.doe@example.com', '2024-01-10', 'Premium'),
('Jane Smith', 'jane.smith@example.com', '2024-01-15', 'Standard'),
('Alice Johnson', 'alice.johnson@example.com', '2024-02-01', 'Basic'),
('Bob Brown', 'bob.brown@example.com', '2024-02-20', 'Premium');

INSERT INTO Movies (title, genre, release_year, rating) VALUES
('Stranger Things', 'Drama', 2016, 8.7),
('Breaking Bad', 'Crime', 2008, 9.5),
('The Crown', 'History', 2016, 8.6),
('The Witcher', 'Fantasy', 2019, 8.2),
('Black Mirror', 'Sci-Fi', 2011, 8.8);

INSERT INTO WatchHistory (user_id, movie_id, watched_date, completion_percentage) VALUES
(1, 1, '2024-02-05', 100),
(2, 2, '2024-02-06', 80),
(3, 3, '2024-02-10', 50),
(4, 4, '2024-02-15', 100),
(1, 5, '2024-02-18', 90);

INSERT INTO Reviews (movie_id, user_id, review_text, rating, review_date) VALUES
(1, 1, 'Amazing storyline and great characters!', 4.5, '2024-02-07'),
(2, 2, 'Intense and thrilling!', 5.0, '2024-02-08'),
(3, 3, 'Good show, but slow at times.', 3.5, '2024-02-12'),
(4, 4, 'Fantastic visuals and acting.', 4.8, '2024-02-16');


-- Q1. List all users subscribed to the Premium plan.
SELECT name, email
FROM Users
WHERE plan = 'Premium';

-- Explanation:
-- Reads only the Users table.
-- WHERE plan = 'Premium' keeps only users on the Premium plan.
-- Expected: John Doe, Bob Brown.


-- Q2. Retrieve all movies in the Drama genre with a rating higher than 8.5.
SELECT title, genre, rating
FROM Movies
WHERE genre = 'Drama' AND rating > 8.5;

-- Explanation:
-- AND means BOTH conditions must be true: genre is Drama AND rating is above 8.5.
-- Expected: Stranger Things (Drama, 8.7).


-- Q3. Find the average rating of all movies released after 2015.
SELECT ROUND(AVG(rating), 2) AS average_rating
FROM Movies
WHERE release_year > 2015;

-- Explanation:
-- WHERE keeps movies released in 2016 or later (Stranger Things, The Crown, The Witcher).
-- AVG(rating) calculates their mean rating: (8.7 + 8.6 + 8.2) / 3 = 8.50.
-- ROUND(..., 2) shows the result with 2 decimals.


-- Q4. List the names of users who have watched Stranger Things
--     along with their completion percentage.
SELECT U.name, W.completion_percentage
FROM Users U
JOIN WatchHistory W ON U.user_id = W.user_id
JOIN Movies M       ON W.movie_id = M.movie_id
WHERE M.title = 'Stranger Things';

-- Explanation:
-- WatchHistory is the link table between Users and Movies.
-- The JOINs connect user -> watch record -> movie.
-- WHERE filters only the 'Stranger Things' watch records.
-- Expected: John Doe, 100.


-- Q5. Find the name of the user(s) who gave the highest rating among all reviews.
SELECT U.name
FROM Users U
JOIN Reviews R ON U.user_id = R.user_id
WHERE R.rating = (SELECT MAX(rating) FROM Reviews);

-- Explanation:
-- The subquery (SELECT MAX(rating) FROM Reviews) finds the highest review rating (5.0).
-- The outer query returns every user whose review rating equals that value.
-- Using a subquery (not LIMIT 1) means all users are shown if there is a tie.
-- Expected: Jane Smith.


-- Q6. Calculate the number of movies watched by each user and sort by the highest count.
SELECT U.name, COUNT(W.watch_id) AS movies_watched
FROM Users U
JOIN WatchHistory W ON U.user_id = W.user_id
GROUP BY U.user_id, U.name
ORDER BY movies_watched DESC, U.name;

-- Explanation:
-- JOIN links each user to their watch records.
-- GROUP BY makes one group per user; COUNT(W.watch_id) counts their watch records.
-- ORDER BY movies_watched DESC puts the highest count first; U.name sorts ties alphabetically.
-- U.name is added to GROUP BY so it also works with ONLY_FULL_GROUP_BY mode.
-- Expected: John Doe 2, then Alice Johnson, Bob Brown, Jane Smith with 1 each.


-- Q7. List all movies watched by John Doe, including genre, rating
--     and his completion percentage.
SELECT M.title, M.genre, M.rating, W.completion_percentage
FROM Movies M
JOIN WatchHistory W ON M.movie_id = W.movie_id
JOIN Users U        ON W.user_id = U.user_id
WHERE U.name = 'John Doe';

-- Explanation:
-- JOINs connect movie -> watch record -> user.
-- WHERE U.name = 'John Doe' keeps only John's watch records.
-- Expected: Stranger Things (Drama, 8.7, 100) and Black Mirror (Sci-Fi, 8.8, 90).


-- Q8. Update the rating of Stranger Things.
UPDATE Movies
SET rating = 8.9
WHERE title = 'Stranger Things';

-- Check the result
SELECT title, rating
FROM Movies
WHERE title = 'Stranger Things';

-- Explanation:
-- UPDATE changes existing data; SET gives the new value (8.7 -> 8.9).
-- WHERE limits the change to Stranger Things only. Without WHERE every movie would change.
-- SQL_SAFE_UPDATES = 0 (top of script) allows this in MySQL Workbench.
-- Expected message: 1 row(s) affected.


-- Q9. Remove all reviews for movies with a rating below 4.0.
DELETE FROM Reviews
WHERE movie_id IN (SELECT movie_id FROM Movies WHERE rating < 4.0);

-- Explanation:
-- The subquery finds the movie_ids of all movies whose rating is below 4.0.
-- DELETE removes every review whose movie_id is in that list.
-- Expected message: 0 row(s) affected.
-- Reason: movie ratings are on a 10-point scale (lowest is 8.2), so no movie is below 4.0.
-- The query is correct; the sample data simply has no matching movie.

-- Optional (other interpretation): delete reviews where the REVIEW rating is below 4.0.
-- This would delete Alice Johnson's 3.5 review of The Crown (1 row).
-- Left commented out so that Q10 and Q12 outputs stay the same.
-- DELETE FROM Reviews WHERE rating < 4.0;


-- Q10. Fetch all users who have reviewed a movie but have not watched it completely
--      (completion percentage < 100).
SELECT U.name, M.title, R.review_text
FROM Users U
JOIN Reviews R ON U.user_id = R.user_id
JOIN Movies M  ON R.movie_id = M.movie_id
LEFT JOIN WatchHistory W
       ON U.user_id = W.user_id AND M.movie_id = W.movie_id
WHERE (W.completion_percentage IS NULL OR W.completion_percentage < 100);

-- Explanation:
-- Starts from reviews (Users + Reviews + Movies).
-- LEFT JOIN WatchHistory on BOTH user_id and movie_id finds whether that user watched that movie.
-- IS NULL catches users who reviewed but never watched; < 100 catches partial watching.
-- Expected: Jane Smith (Breaking Bad, 80%) and Alice Johnson (The Crown, 50%).


-- Q11. List all movies watched by John Doe along with their genre
--      and his completion percentage.
SELECT M.title, M.genre, W.completion_percentage
FROM Movies M
JOIN WatchHistory W ON M.movie_id = W.movie_id
JOIN Users U        ON W.user_id = U.user_id
WHERE U.name = 'John Doe';

-- Explanation:
-- Same as Q7, but without the movie rating column.
-- Expected: Stranger Things (Drama, 100) and Black Mirror (Sci-Fi, 90).


-- Q12. Retrieve all users who have reviewed Stranger Things,
--      including their review text and rating.
SELECT U.name, R.review_text, R.rating
FROM Users U
JOIN Reviews R ON U.user_id = R.user_id
JOIN Movies M  ON R.movie_id = M.movie_id
WHERE M.title = 'Stranger Things';

-- Explanation:
-- JOINs connect user -> review -> movie.
-- WHERE keeps only reviews for Stranger Things.
-- R.rating is the user's review rating (out of 5), not the movie's rating.
-- Expected: John Doe, 'Amazing storyline and great characters!', 4.5.


-- Q13. Fetch the watch history of all users, including name, email, movie title,
--      genre, watched date and completion percentage.
SELECT U.name, U.email, M.title, M.genre, W.watched_date, W.completion_percentage
FROM Users U
JOIN WatchHistory W ON U.user_id = W.user_id
JOIN Movies M       ON W.movie_id = M.movie_id
ORDER BY W.watched_date;

-- Explanation:
-- Joins all three tables to replace IDs with readable names.
-- No WHERE clause, so every watch record is returned (5 rows).
-- ORDER BY watched_date lists them from oldest to newest.


-- Q14. List all movies with the total number of reviews and average rating,
--      including only movies with at least two reviews.
SELECT M.title,
       COUNT(R.review_id)     AS total_reviews,
       ROUND(AVG(R.rating), 2) AS average_rating
FROM Movies M
JOIN Reviews R ON M.movie_id = R.movie_id
GROUP BY M.movie_id, M.title
HAVING COUNT(R.review_id) >= 2;

-- Explanation:
-- GROUP BY makes one group per movie.
-- COUNT counts the reviews and AVG gives the average review rating for each movie.
-- HAVING filters groups after grouping: only movies with 2 or more reviews.
-- Expected: empty result. Every movie has only 1 review in the sample data,
-- so no movie meets the ">= 2 reviews" condition. The query itself is correct.

-- Optional demo: add a second review for Stranger Things, then re-run Q14.
-- Result would be: Stranger Things | 2 | 4.65
-- INSERT INTO Reviews (movie_id, user_id, review_text, rating, review_date)
-- VALUES (1, 2, 'Loved the 80s vibe!', 4.8, '2024-02-20');


-- Turn safe update mode back on (good practice)
SET SQL_SAFE_UPDATES = 1;
