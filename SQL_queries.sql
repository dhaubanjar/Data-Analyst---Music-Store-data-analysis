SELECT * FROM employee;

-- 1. Who is the senior most employee based on each job title?

WITH ranked_employees AS (
	SELECT 
		first_name, 
		last_name, 
		title, 
		levels, 
		ROW_NUMBER() OVER (PARTITION BY title ORDER BY levels ASC) AS rn
FROM employee
)

SELECT 
	CONCAT(first_name, ' ', last_name) AS Full_Name,
	title,
	levels,
	rn as Rank 
FROM ranked_employees where rn =1;


-- 2. Which are top 10 countries having the most Invoices?

SELECT 
	count(*) as Total_invoices, 
	billing_country 
	from invoice 
	group by billing_country 
	order by Total_invoices 
	desc limit 10;

-- 3. List all the tracks from album with ID 10 sorted according to the track name

WITH album_rank AS (
	SELECT 
		album."album_id" AS Album_ID, 
		album."title" AS Album_name, 
		track."name" AS Track_name,
		row_number() over(PARTITION BY album."title" ORDER BY track."name" ASC) AS RN 
		FROM 
			album 
		join 
			track ON album."album_id" = track."album_id"
)

SELECT 
	RN as Rank,
	Album_ID, 
	Album_name, 
	Track_name
	
from
	album_rank WHERE Album_ID = '10';


-- 3. Which city has the best customers? We would like to throw a promotional Music 
-- Festival in the city we made the most money. Write a query that returns one city that 
-- has the highest sum of invoice totals. Return both the city name & sum of all invoice 
-- totals

SELECT 
	invoice.billing_city as City, 
	sum(invoice.total) as Total 
	from 
		invoice
	group by City
	order by Total DESC LIMIT 1;

-- 4. Who is the best customer? The customer who has spent the most money will be 
-- declared the best customer. Write a query that returns the person who has spent the 
-- most money

SELECT C.customer_id, concat(C.first_name, ' ', C.last_name) AS Customer_Name, 
	cast(sum(I.total) AS numeric) AS Total
	from customer C 
	JOIN invoice I ON
	C.customer_id = I.customer_id
	GROUP by C.customer_id
	Order by Total DESC
	LIMIT 1;


-- 5. Write query to return the email, first name, last name, & Genre of all Rock Music 
-- listeners. Return your list ordered alphabetically by email starting with A

SELECT DISTINCT
	c.email, 
	c.first_name, 
	c.last_name  
	FROM customer c 
	JOIN invoice i 
	on i.customer_id = c.customer_id
	JOIN invoice_line il
	on i.invoice_id = il.invoice_id
	WHERE track_id IN(
		select	track_id from track t
		join genre g on t.genre_id = g.genre_id
		where g.name LIKE 'Rock'
	)
	ORDER BY email;


-- 6. Let's invite the artists who have written the most rock music in our dataset.
-- 	Write a query that returns the Artist's name and total track count of the top 10 rock bands.


SELECT 
	a.artist_id,
	a.name,
	count(a.artist_id) as total_track
	FROM artist a join 
	album al 
	on al.artist_id = a.artist_id
	JOIN track t
	on al.album_id = t.album_id
	WHERE genre_id in (
		select g.genre_id from track t
		join genre g
		on t.genre_id = g.genre_id
		where g.name LIKE 'Rock'
	)
	group by a.artist_id
	ORDER by total_track desc
	LIMIT 10;

-- 7. Return all the track names that have a song length longer than the average song length.
-- Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. 

track names 
miliseconds > avg(miliseconds)
order song length DESC

select
	track_id,
	name,
	milliseconds,
	Round(avg(milliseconds) over() ,2) AS avg_song_length
	
	FROM track t
	where milliseconds > (
		select avg(track_id) AS average_length
		from track)
	order by milliseconds desc;	


--8. Find how much amount spent by each customer on a top artist? Write a query to return 
-- customer name, artist name and total spent.ABORT



WITH best_selling_artist AS (
SELECT 
	a.artist_id,
	a.name AS Artist_name,
	il.unit_price, il.quantity,
	sum(il.unit_price * il.quantity) AS Total_cost
	FROM artist a
	JOIN album al
	ON al.artist_id = a.artist_id
	JOIN track t
	ON t.album_id = al.album_id
	JOIN invoice_line il
	ON il.track_id = t.track_id
	GROUP by a.artist_id, il.unit_price, il.quantity
	ORDER by Total_cost Desc
	Limit 1
)
SELECT 
	c.customer_id,
	concat(c.first_name, ' ' , c.last_name) AS Full_name,
	bsa.artist_name,
	round(cast(sum(il.unit_price * il.quantity) AS Numeric),2) AS Amount_spent
	FROM invoice i
	JOIN customer c ON c.customer_id = i.customer_id
	JOIN invoice_line il ON il.invoice_id = i.invoice_id
	JOIN track t ON t.track_id = il.track_id
	JOIN album al ON al.album_id = t.album_id
	JOIN best_selling_artist bsa ON bsa.artist_id = al.artist_id
GROUP by 1,2,3
ORDER by Amount_spent DESC
;


--9. We want to find out the most popular music Genre for each country. 
-- We determine the 
-- most popular genre as the genre with the highest amount of purchases. Write a query 
-- that returns each country along with the top Genre. For countries where the maximum 
-- number of purchases is shared return all Genres

WITH country_with_most_purchase AS (
SELECT
    Country,
    Genre,
    Total_purchase,
    ROW_NUMBER() OVER (PARTITION BY Country ORDER BY Total_purchase DESC) AS mf
FROM (
    SELECT
        i.billing_country AS Country,
        g.name AS Genre,
        COUNT(*) AS Total_purchase
    FROM invoice i
    JOIN invoice_line il ON il.invoice_id = i.invoice_id
    JOIN track t ON t.track_id = il.track_id
    JOIN genre g ON g.genre_id = t.genre_id
    GROUP BY i.billing_country, g.name
) AS subquery
ORDER BY Country, Total_purchase DESC

)

SELECT * from country_with_most_purchase where mf <=1

-- 10. Write a query that determines the customer that has spent the most on music for each 
-- country. Write a query that returns the country along with the top customer and how
-- much they spent. For countries where the top amount spent is shared, provide all 
-- customers who spent this amount


with customer_total as (
	select 
	i.customer_id, 
	concat(c.first_name, ' ', c.last_name) as Full_name, 
	i.billing_country, 
	sum(i.total) OVER (PARTITION by i.billing_country ) as Total_purchase,
	row_number() over( partition by i.billing_country  ) as row_num
	from invoice i 
	join 
	customer c 
	ON c.customer_id = i.customer_id
	
)
select 
	customer_id,  
	Full_name, 
	billing_country, 
	Total_Purchase 
from 
	customer_total where row_num <=1 order by billing_country ASC




