-- =====================================================================
-- 01_film_and_payment_filters.sql
-- Business question: Where does our film pricing diverge from what
-- customers actually pay?
-- Authors: Simon Tao, Gourav Jagde
-- Database: Sakila (MySQL 8.0+)
-- =====================================================================
USE sakila;

#Q1 Find the number of movies with a rental rate greater than 2.99, a length between 90 and 120 minutes, and a replacement cost of less than 20.00. 
	# The movie title must contain the letter ‘A’ and must not be rated ‘NC-17’ or ‘R’.
SELECT 
	COUNT(*) AS movie_count 
	FROM film 
	WHERE 
		rental_rate > 2.99 
		AND (length >= 90 AND length <= 120) 
		AND replacement_cost < 20.00 
		AND title LIKE '%A%' 
		AND rating NOT IN ('NC-17', 'R');

#Q2 Find all actors whose first name starts with ‘A’, ‘B’, or ‘C’, and whose last name ends with ‘SON’ or ‘SEN’. 
	# Additionally, the full name (first and last name combined, including the space) must be longer than 12 characters. 
	# Display the first name, last name, and the total length of the full name. Order the results by last name, then by first name.
SELECT 
	first_name, 
    last_name, 
    LENGTH(CONCAT(first_name, ' ', last_name)) 
    AS full_name_length 
    FROM actor 
    WHERE 
		(first_name LIKE 'A%' OR first_name LIKE 'B%' OR first_name LIKE 'C%') 
		AND (last_name LIKE '%SON' OR last_name LIKE '%SEN') 
		AND LENGTH(CONCAT(first_name, ' ', last_name)) > 12
	ORDER BY 
		last_name, 
		first_name;

#Q3 Find all payments where the amount is not between 2.00 and 5.00, the payment was made in July 2005, and the customer ID is an even number (ending in 0, 2, 4, 6, or 8). 
	# Display the payment ID, customer ID, rental ID, amount, and payment date. Order the results by amount in descending order, then by payment date.
SELECT 
	payment_id,
    customer_id,
    rental_id,
    amount,
    payment_date
	FROM payment
	WHERE 
		(amount < 2.00 OR amount > 5.00)
		AND YEAR(payment_date) = 2005
		AND MONTH(payment_date) = 7
		AND customer_id % 2 = 0
	ORDER BY 
		amount DESC,
		payment_date;

#Q4 Find the titles of all movies whose rental rate is higher than the average payment amount in the payment table 
	# and whose length (in minutes) is greater than twice the minimum rental duration in the film table.
SELECT 
	title,
    rental_duration, 
    rental_rate, 
    length 
    FROM film 
    WHERE 
		length > 2 * (SELECT MIN(rental_duration) FROM film)
        AND rental_rate > (
				SELECT AVG(amount) AS avgpmt 
					FROM payment
			)
	ORDER BY 
		length DESC;

#Q5 Find movies whose rental duration is greater than the maximum rental duration of movies rated ‘PG’, but whose rating is not ‘PG’.
SELECT 
    film_id,
    title,
    length,
    rental_duration,
    rating
	FROM film
	WHERE 
		rental_duration > (
			SELECT MAX(rental_duration)
				FROM film
				WHERE rating = 'PG'
		)
		AND rating != 'PG'
	ORDER BY 
		length DESC;
