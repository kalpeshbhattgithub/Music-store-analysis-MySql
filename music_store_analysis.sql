#Q1 : Who is the senior most employee based on job title?

Select * from music_database.employee
order by levels desc
limit 1

#Q2 : Which countries have the most invoices?

Select COUNT(*) AS Most_Invoiced_country , billing_country from music_database.invoice
Group by billing_country
Order by Most_Invoiced_country desc

#Q3 : What are top 3 values of total invoice?

Select total fROM music_database.invoice
order by total desc 
limit 3

/*Q4 : Which city has the best customers? We would like to throw a promotional Music Festival in the city
	 we made the most money. Write a query that returns one city that has the highest sum of invoice totals.
     Return both the city name & sum of all invoice totals.*/
	
Select sum(total) as highest_sum_of_invoice, billing_city From music_database.invoice
Group by billing_city 
order by highest_sum_of_invoice desc


/*Q5 : Who is the best customer? The customer who has spent money will be declaired the
        best customer. Write a query that returns the person who has spent the most money.*/
        
Select customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total) as total
from music_database.customer
Join music_database.invoice on customer.customer_id = invoice.Customer_id
Group by customer.customer_id
order by total desc
limit 1       

 /*Q6 :Write query to return the email, first name, last name and Genre of all Rock Music Listeners.
       Return your list ordered alphabatically by email starting with A.*/ 
       
SELECT DISTINCT email,first_name,last_name From music_database.customer
JOIN music_database.invoice ON customer.customer_id = invoice.customer_id
JOIN music_database.invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN (
    SELECT track_id FROM music_database.track
    JOIN music_database.genre ON track.genre_id = genre.genre_id
    WHERE music_database.genre.name LIKE 'Rock'
)
order by email;

/*Q7 : Let's invite the artists who have written the most rock music in
       our dataset. Write a query that returns the Artist name and total
	   track count of the top 3 rock bands.*/
SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) as number_of_songs 
FROM music_database.track
JOIN music_database.album2 ON album2.album_id = track.album_id
JOIN music_database.artist ON artist.artist_id = album2.artist_id
JOIN music_database.genre ON genre.genre_id = track.genre_id
WHERE music_database.genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 3;

/*Q8 : Return all the track names that have a song length longer than the average song length. 
	   Return the name and miliseconds for each track. Order by the song length with the longest
       songs listed first.*/
       
SELECT name, milliseconds 
FROM music_database.track
WHERE track.milliseconds > (
      SELECT AVG(milliseconds) AS avg_track_length
      FROM music_database.track)
ORDER BY track.milliseconds DESC;

/*Q9: Find how much amount spent by each customer on artists? Write a query 
      to return customer name, artist name and total spent.*/
      
WITH best_selling_artist  AS (
     SELECT artist.artist_id as artist_id, artist.name AS artist_name,
     SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
     FROM music_database.invoice_line
     JOIN music_database.track ON track.track_id = invoice_line.track_id
     JOIN music_database.album2 ON album2.album_id =track.album_id
     JOIN music_database.artist ON artist.artist_id = album2.artist_id
     GROUP BY artist_id
     ORDER BY total_sales DESC
     LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity)
AS amount_spent FROM music_database.invoice i 
JOIN music_database.customer c ON c.customer_id = i.customer_id
JOIN music_database.invoice_line il ON il.invoice_id = i.invoice_id
JOIN music_database.track t ON t.track_id = il.track_id
JOIN music_database.album2 alb ON alb.album_id =t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;      

/* Q10 : We want to find out the most popular music Genre for each country. We determine
         the most popular genre as the genre with the highest amount of purchases. Write
         a query that returns each country along with the top Genre. For countries where 
         the maximum number of purchases is shared return all genres.*/
WITH popular_genre AS (
SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.genre_id,
ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
FROM music_database.invoice_line
JOIN music_database.invoice ON invoice.invoice_id = invoice_line.invoice_id
JOIN music_database.customer ON customer.customer_id =invoice.customer_id
JOIN music_database.track ON track.track_id = invoice_line.track_id
JOIN music_database.genre ON genre.genre_id = track.genre_id
GROUP BY 2,3,4
ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

/*Mehtod : 2 */
WITH RECURSIVE 
   sales_per_country AS (
      SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.genre_id,genre.name 
      FROM music_database.invoice_line
      JOIN music_database.invoice ON invoice.invoice_id = invoice_line.invoice_id
	  JOIN music_database.customer ON customer.customer_id =invoice.customer_id
      JOIN music_database.track ON track.track_id = invoice_line.track_id
	  JOIN music_database.genre ON genre.genre_id = track.genre_id
      GROUP BY 2,3,4
      ORDER BY 2
   ),
   max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
      FROM sales_per_country
      GROUP BY 2
      ORDER BY 2)
   
SELECT sales_per_country.*
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number
    