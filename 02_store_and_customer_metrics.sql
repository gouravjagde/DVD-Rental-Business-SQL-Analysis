-- =====================================================================
-- 02_store_and_customer_metrics.sql
-- Business question: Are the two stores performing equally, and which
-- customers and titles drive the revenue?
-- Authors: Simon Tao, Gourav Jagde
-- Database: Sakila (MySQL 8.0+)
-- =====================================================================
USE sakila;

#Question 1 Show the customer’s full name (formatted as first name, space, last name), total number of rentals, 
#and total amount spent for customers who have made more than 30 rentals and spent over $150 in total.
SELECT 
    CONCAT(customer.first_name, ' ', customer.last_name) AS customer_name,
    COUNT(rental.rental_id) AS total_rentals,
    SUM(payment.amount) AS total_spent
	FROM customer
	JOIN rental ON customer.customer_id = rental.customer_id
	JOIN payment ON rental.rental_id = payment.rental_id
	GROUP BY customer.customer_id, customer.first_name, customer.last_name
	HAVING
		COUNT(rental.rental_id) > 30
		AND SUM(payment.amount) > 150.00
	ORDER BY total_spent DESC;

#Question 2 Compare the two stores showing total revenue, number of rentals, average rental value (rounded by two), and number of unique customers for each store.
SELECT 
    store.store_id, 
    SUM(payment.amount) AS 'Total Revenue', 
    COUNT(rental.rental_id) AS 'Number of Rentals', 
    ROUND(AVG(payment.amount), 2) AS 'Average Rental Value', 
    COUNT(DISTINCT rental.customer_id) AS 'Unique Customers'
	FROM store
	JOIN inventory ON store.store_id = inventory.store_id
	JOIN rental ON inventory.inventory_id = rental.inventory_id
	JOIN payment ON rental.rental_id = payment.rental_id
	GROUP BY store.store_id;

#Question 3 Find customers who have returned films late more than 5 times. Show customer’s full name, number of late returns, and average days late.
SELECT 
    CONCAT(customer.first_name, ' ', customer.last_name) AS 'Full Name',
    COUNT(rental.rental_id) AS 'Late Returns',
    ROUND(AVG(DATEDIFF(rental.return_date, rental.rental_date) - film.rental_duration), 2) AS 'Avg Days Late'
	FROM customer
	JOIN rental ON customer.customer_id = rental.customer_id
	JOIN inventory ON rental.inventory_id = inventory.inventory_id
	JOIN film ON inventory.film_id = film.film_id
	WHERE DATEDIFF(rental.return_date, rental.rental_date) > film.rental_duration
	GROUP BY customer.customer_id, customer.first_name, customer.last_name
	HAVING COUNT(rental.rental_id) > 5;

#Question 4 Write a query to analyze the performance of PG-13 and R-rated movies across stores.
#Show only results where the movie was rented at least 15 times and generated more than $60 in total revenue.
#Display the movie title, store ID, total number of rentals, and total revenue generated from each movie at each store and
#order your results by total revenue (highest first), then by number of rentals (highest first), and limit the output to the top 15 results.
SELECT 
    film.title AS movie_title,
    inventory.store_id,
    COUNT(DISTINCT rental.rental_id) AS total_rentals,
    SUM(payment.amount) AS total_revenue
	FROM film
	JOIN inventory ON film.film_id = inventory.film_id
	JOIN rental ON inventory.inventory_id = rental.inventory_id
	JOIN payment ON rental.rental_id = payment.rental_id
	WHERE film.rating = 'PG-13' OR film.rating = 'R'
	GROUP BY film.film_id, film.title, inventory.store_id
	HAVING 
		COUNT(DISTINCT rental.rental_id) >= 15
		AND SUM(payment.amount) > 60.00
	ORDER BY 
		total_revenue DESC,
		total_rentals DESC
	LIMIT 15;

#Question 5 Create a view showing all staff members with their store’s address information (address, district, city). 
#Include only staff from stores in cities starting with ’L’. Then query the view to find staff members whose store is in the ’Alberta’ district.

#Create the view (CREATE OR REPLACE so the script can be re-run);
CREATE OR REPLACE VIEW staff_store_locations AS
	SELECT 
		staff.staff_id,
		CONCAT(staff.first_name, ' ', staff.last_name) AS staff_name,
		staff.email,
		staff.username,
		staff.active,
		staff.store_id AS assigned_store_id,
		address.address AS store_address,
		address.address2 AS store_address2,
		address.district AS store_district,
		city.city AS store_city,
		country.country AS store_country
		FROM staff
		JOIN store ON staff.store_id = store.store_id
		JOIN address ON store.address_id = address.address_id
		JOIN city ON address.city_id = city.city_id
		JOIN country ON city.country_id = country.country_id
		WHERE city.city LIKE 'L%';

#Query the view;
SELECT 
    staff_id,
    staff_name,
    email,
    assigned_store_id,
    store_address,
    store_district,
    store_city,
    store_country
	FROM staff_store_locations
	WHERE store_district = 'Alberta'
	ORDER BY staff_name;
