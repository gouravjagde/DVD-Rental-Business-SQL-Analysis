-- =====================================================================
-- 03_inventory_overlap_and_category_hierarchy.sql
-- Business question: Is our inventory and catalog organized around how
-- customers actually rent?
-- Authors: Simon Tao, Gourav Jagde
-- Database: Sakila (MySQL 8.0+)
--
-- WARNING: Question 4 alters the category table (adds parent_category_id).
-- Run that section only once. To undo it:
--   ALTER TABLE category
--     DROP FOREIGN KEY fk_category_parent,
--     DROP COLUMN parent_category_id;
-- =====================================================================
USE sakila;

# Question 1: Stores pay for shelf space and want to remove films that don’t generate rentals. Each
# store needs to optimize its unique inventory.
# Find all inventory items at Store 1 that have NEVER been rented. Show inventory ID, film title,
# category, and replacement cost.

SELECT 
    inventory.inventory_id, 
    film.title, 
    category.name AS category, 
    film.replacement_cost
FROM inventory
JOIN film ON inventory.film_id = film.film_id
JOIN film_category ON film.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id
LEFT JOIN rental ON inventory.inventory_id = rental.inventory_id
WHERE inventory.store_id = 1
  AND rental.rental_id IS NULL
ORDER BY category.name, film.title;


# Question 2: The studio wants to compare “Versatile” actors (those who’ve worked in 5+ different
# genres) with “Specialized” actors (those who’ve worked in fewer than 3 genres).
# Create a single result set using UNION that shows two groups: (1) versatile actors with their genre
# count, labeled as “Versatile”, and (2) specialized actors with their genre count, labeled as “Specialized”.
# Include actor name, genre count, and type label.

# Versatile actors
SELECT 
    CONCAT(actor.first_name, ' ', actor.last_name) AS actor_name,
    COUNT(DISTINCT film_category.category_id) AS genre_count,
    'Versatile' AS actor_type
FROM actor
JOIN film_actor ON actor.actor_id = film_actor.actor_id
JOIN film_category ON film_actor.film_id = film_category.film_id
GROUP BY actor.actor_id, actor.first_name, actor.last_name
HAVING COUNT(DISTINCT film_category.category_id) >= 5

UNION

# Specialized actors
SELECT 
    CONCAT(actor.first_name, ' ', actor.last_name) AS actor_name,
    COUNT(DISTINCT film_category.category_id) AS genre_count,
    'Specialized' AS actor_type
FROM actor
JOIN film_actor ON actor.actor_id = film_actor.actor_id
JOIN film_category ON film_actor.film_id = film_category.film_id
GROUP BY actor.actor_id, actor.first_name, actor.last_name
HAVING COUNT(DISTINCT film_category.category_id) < 3

ORDER BY actor_type, genre_count DESC, actor_name;

# Question 3: Write a query that finds, for each customer X, another customer Y who has rented
# atleast one movie in common with X. Find all such pairs of Customers (X, Y) and against each pair,
# the number of overlapping movies. The query should thus have three columns. Order the results by the
# number of overlapping movies.
# Hint: Create a view that lists customer (id) and the movies that they have rented. Join this view
# with itself

# Create a view for customer rentals
DROP VIEW IF EXISTS customer_rentals;
CREATE VIEW customer_rentals AS
SELECT 
    rental.customer_id,
    inventory.film_id
FROM rental
JOIN inventory ON rental.inventory_id = inventory.inventory_id;

# Self-join to find overlapping rentals
SELECT 
    customer_rentals_1.customer_id AS customer_x,
    customer_rentals_2.customer_id AS customer_y,
    COUNT(DISTINCT customer_rentals_1.film_id) AS overlapping_movies
FROM customer_rentals AS customer_rentals_1
JOIN customer_rentals AS customer_rentals_2
  ON customer_rentals_1.film_id = customer_rentals_2.film_id
WHERE customer_rentals_1.customer_id NOT IN (customer_rentals_2.customer_id)
GROUP BY customer_rentals_1.customer_id, customer_rentals_2.customer_id
ORDER BY overlapping_movies DESC;

# Question 4: Turn the flat category table into a two-level hierarchy.
# Task 1: add a self-referencing column for the parent category (run this only once).
# Note: the column type must match category.category_id (TINYINT UNSIGNED in the standard Sakila schema).
ALTER TABLE category
	ADD COLUMN parent_category_id TINYINT UNSIGNED DEFAULT NULL,
	ADD CONSTRAINT fk_category_parent
		FOREIGN KEY (parent_category_id)
		REFERENCES category(category_id)
		ON DELETE RESTRICT
        ON UPDATE CASCADE;
        
# Task 2: assign each subcategory to its parent.
# Step 1: look up the three parent IDs by name.
SET @action_id = (SELECT category_id FROM category WHERE name = 'Action');
SET @drama_id  = (SELECT category_id FROM category WHERE name = 'Drama');
SET @family_id = (SELECT category_id FROM category WHERE name = 'Family');

# Step 2: point each subcategory at its parent.
# Each UPDATE filters on the key column (category_id) so it also runs under MySQL Workbench's safe-update mode,
# and repeats the name as a double-check: a wrong ID simply updates nothing instead of the wrong row.
# Action
UPDATE category 
	SET parent_category_id = @action_id
	WHERE category_id IN (14,15,16)
		AND name IN ('Sci-Fi','Sports','Travel');

# Drama
UPDATE category 
	SET parent_category_id = @drama_id
	WHERE category_id IN (6,9,12)
		AND name IN ('Documentary','Foreign','Music');

# Family
UPDATE category 
	SET parent_category_id = @family_id
	WHERE category_id IN (2,3,4,5,10)
		AND name IN ('Animation','Children','Classics','Comedy','Games');

# Check the hierarchy (New and Horror stay top-level, so they show no parent)
SELECT 
	category.category_id,
	category.name AS category,
	parent.name AS parent_category
FROM category
LEFT JOIN category AS parent ON category.parent_category_id = parent.category_id
ORDER BY parent.name, category.name;

# Task 3: which subcategory has the most films? Report the name and the number of films.
SELECT 
	sub.name AS subcategory,
	parent.name AS parent_category,
	COUNT(film_category.film_id) AS film_count
FROM category AS sub
JOIN category AS parent ON sub.parent_category_id = parent.category_id
JOIN film_category ON sub.category_id = film_category.category_id
GROUP BY sub.category_id, sub.name, parent.name
ORDER BY film_count DESC
LIMIT 1;

# Bonus: the same count rolled up to each parent category
SELECT 
	parent.name AS parent_category,
	COUNT(DISTINCT film_category.film_id) AS film_count
FROM category AS parent
JOIN category AS sub ON sub.parent_category_id = parent.category_id
JOIN film_category ON sub.category_id = film_category.category_id
GROUP BY parent.category_id, parent.name
ORDER BY film_count DESC;
