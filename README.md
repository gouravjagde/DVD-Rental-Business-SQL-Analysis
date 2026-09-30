# DVD Rental Business SQL Analysis

Repository: https://github.com/gouravjagde/DVD-Rental-Business-SQL-Analysis

SQL analysis of the [Sakila sample database](https://dev.mysql.com/doc/sakila/en/), a fictional two-store DVD rental business (1,000 films, 599 customers, 16,044 rentals, about $67.4K in payments). Each script is built around questions a manager would actually ask, and each section below gives the question, the result, and what it means. One script also changes the schema to turn the flat `category` table into a two-level hierarchy.

## Business questions answered

### `01_film_and_payment_filters.sql` — Where does our film pricing diverge from what customers actually pay?

- **Which mid-length, non-adult titles have the best rent-to-replacement economics?** Films that rent above $2.99, run 90-120 minutes, cost under $20 to replace, and are not rated R or NC-17 (title contains "A"). Result: **23 films**, a ready shortlist for promotion.
- **How much July 2005 revenue came from payments outside the normal $2-$5 band?** Even-numbered customer IDs serve as a 50% audit sample. Result: **1,571 payments totaling $6,948.29**.
- **Are we pricing above what customers pay on average?** Result: **336 films (34% of the catalog)** sit at the $4.99 tier, against an average payment of $4.20.
- **Does any rating earn a longer rental window than PG?** Result: **none**. PG already holds the 7-day maximum, so the query correctly returns zero rows. Rating is not a lever for rental terms.
- **Talent shortlist:** actors with first initial A-C, last name ending in SON/SEN, and a full name over 12 characters. A search utility rather than a metric.

### `02_store_and_customer_metrics.sql` — Are the two stores performing equally, and which customers and titles drive the revenue?

- **Store comparison:** Store 1 brought in **$33,679.79** on 7,923 rentals ($4.25 average). Store 2 brought in **$33,726.77** on 8,121 rentals ($4.15 average). Both reach all 599 customers. Revenue differs by 0.14%, so the stores are effectively interchangeable; Store 2 wins on volume and Store 1 on ticket size.
- **High-value customers (30+ rentals and more than $150 spent):** **45 of 599 customers (7.5%)** generate **$7,436.83, or 11% of all revenue**.
- **Repeat late returners (more than 5 late returns, and by how many days on average):** **589 of 599 customers** qualify (worst case: 25 late returns; highest average lateness 4.7 days). A count-based flag is too loose to be useful here; a late-return *rate* would separate habitual offenders from everyone else.
- **Top R and PG-13 titles per store (at least 15 rentals and over $60 in revenue, top 15):** the leader is **WHALE BIKINI at Store 1** (18 rentals, $134.82), and **11 of the top 15** are Store 1 copies.
- **Staff directory view:** `staff_store_locations` joins staff, store, address, city and country, filtered to cities starting with "L" and then queried for the Alberta district. It returns the Lethbridge store's staff member.

### `03_inventory_overlap_and_category_hierarchy.sql` — Is our inventory and catalog organized around how customers actually rent?

- **Which Store 1 inventory has never been rented and should be cut?** Result: **none**. All 2,270 Store 1 items were rented at least once (1 to 5 times, averaging 3.5). The only never-rented copy in the chain is at Store 2. The shelf-space question needs a rental-frequency ranking instead.
- **Are actors versatile (5+ genres) or specialized (fewer than 3)?** Result: **all 200 actors are versatile**, averaging about 13 of 16 genres. No specialized actors exist, so specialization is not a useful segment in this dataset.
- **Which customers share taste (the basis for "customers like you also rented")?** A `customer_rentals` view joined to itself finds **197,238 ordered pairs** (98,619 unique) with at least one film in common. The maximum overlap is **7 films**, reached by 5 unique pairs (for example customers 197 and 267). Pairs sharing 5 or more films (264 unique) are a sensible starting point for recommendation rules.
- **How should categories be organized?** A self-referencing `parent_category_id` foreign key groups subcategories under **Action** (Sports, Sci-Fi, Travel), **Drama** (Documentary, Foreign, Music) and **Family** (Animation, Children, Classics, Comedy, Games). Horror and New stay top-level.
- **Which subcategory has the most films?** **Sports (Action) with 74**, followed by Foreign (73) and Documentary (68). Rolled up to parent level, Family is the largest at 302 films.

## SQL techniques used

| Area | What's in the scripts |
|---|---|
| Aggregation | `COUNT`, `SUM`, `AVG`, `ROUND`, `GROUP BY`, `HAVING`, `COUNT(DISTINCT ...)` |
| Joins | 4-5 table `INNER JOIN` chains, `LEFT JOIN ... IS NULL` anti-join, self-join on a view |
| Subqueries | Scalar subqueries in `WHERE` (average payment, max PG rental duration), subquery inside `UPDATE` |
| Set operations | `UNION` with a computed label column |
| Dates and strings | `DATEDIFF`, `YEAR`/`MONTH`, `CONCAT`, `LENGTH`, `LIKE` |
| Schema design | `CREATE VIEW`, `ALTER TABLE ... ADD CONSTRAINT`, self-referencing foreign key with `ON DELETE RESTRICT` / `ON UPDATE CASCADE` |

## Repository layout

```text
sql/
  01_film_and_payment_filters.sql
  02_store_and_customer_metrics.sql
  03_inventory_overlap_and_category_hierarchy.sql
README.md
```

## Running it

Requires MySQL 8.0+ with the Sakila schema and data loaded.

```bash
git clone https://github.com/gouravjagde/DVD-Rental-Business-SQL-Analysis.git
cd DVD-Rental-Business-SQL-Analysis

mysql -u root -p sakila < sql/01_film_and_payment_filters.sql
mysql -u root -p sakila < sql/02_store_and_customer_metrics.sql
mysql -u root -p sakila < sql/03_inventory_overlap_and_category_hierarchy.sql
```

Or open each file in MySQL Workbench, DBeaver or DataGrip and run it against the `sakila` database.

**Script 03 modifies the sample database.** The `ALTER TABLE` statement adds a column and a foreign key to `category`, so it can only be run once. `parent_category_id` must match the type of `category_id` (`TINYINT UNSIGNED` in the standard Sakila schema). To undo the change:

```sql
ALTER TABLE category
  DROP FOREIGN KEY fk_category_parent,
  DROP COLUMN parent_category_id;
```

## Design notes and limitations

- **Revenue metrics go through `rental` to `payment`.** Rentals with no payment record are excluded from revenue and average-value figures.
- **"Late" means the film was held longer than its `rental_duration`.** Rentals that were never returned are excluded because their return date is `NULL`.
- **The customer overlap query returns each pair twice**, as (X, Y) and (Y, X). It joins on `film_id` before counting, so it is slow on the full rental table. Deduplicating the view to distinct customer-film pairs, or adding an index on the join column, would help.
- **This is a co-occurrence table, not a recommender.** It could feed a recommendation step, but no scoring or filtering logic is included.
- **Not used yet:** window functions and recursive CTEs.

## Possible extensions

- Rank Store 1 inventory by rental count to answer the shelf-space question properly.
- Replace the late-return count with a late-return rate per customer.
- Rank films within each store by revenue using window functions (`RANK() OVER (PARTITION BY store_id ...)`).
- Traverse the category hierarchy with a recursive CTE.
- Build a Power BI dashboard on top of the views.
- Add an ERD of the tables used to `docs/`.

## Authors

Simon Tao and Gourav Jagde. Originally developed for BUS 464 (Business Data Management) at SFU's Beedie School of Business, then reorganized as a standalone analysis.
