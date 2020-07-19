-- Which tracks appeared in the most playlists? how many playlist did they appear in?
SELECT Name AS 'Track', COUNT(PlaylistId) AS 'number_in_playlists'
FROM playlist_track AS pt
JOIN tracks AS t
ON pt.TrackId = t.TrackId
GROUP BY pt.TrackId
ORDER BY 2 DESC
LIMIT 10;


-- Which track generated the most revenue?
SELECT  tracks.TrackId, tracks.Name, SUM(Total) AS 'Total Revenue'
FROM tracks JOIN invoice_items
ON tracks.TrackId = invoice_items.TrackId
JOIN invoices
ON invoice_items.InvoiceId = invoices.InvoiceId
GROUP BY 1
ORDER BY 3 DESC
LIMIT 10;

-- which album?
SELECT  albums.Title, ROUND(SUM(Total)) AS 'Total_Revenue'
FROM albums JOIN tracks
ON albums.AlbumId = tracks.AlbumId
JOIN invoice_items
ON tracks.TrackId = invoice_items.TrackId
JOIN invoices
ON invoice_items.InvoiceId = invoices.InvoiceId
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- which genre?
SELECT genres.Name, ROUND(SUM(Total)) AS 'total_revenue'
FROM genres LEFT JOIN tracks
ON genres.GenreId = tracks.GenreId
JOIN invoice_items
ON tracks.TrackId = invoice_items.TrackId
JOIN invoices
ON invoice_items.InvoiceId = invoices.InvoiceId
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Which countries have the highest sales revenue? What percent of total revenue does each country make up?
SELECT Country, SUM(Total),
    ROUND(Total/SUM(Total), 4) * 100.0 AS 'percent_share'  FROM invoices
JOIN customers
ON invoices.CustomerId = customers.CustomerId
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- How many customers did each employee support, what is the average revenue for each sale, and what is their total sale?
WITH total_avg_revenue AS
( SELECT SUM(Total) AS 'customer_total', COUNT(invoiceId) AS 'no_of_invoices', customers.CustomerId,
  SupportRepId 
  FROM  customers JOIN invoices
  ON customers.CustomerId = invoices.CustomerId
  GROUP BY customers.CustomerId
  )
  SELECT EmployeeId, FirstName, LastName, COUNT(CustomerId) AS 'num_customers_supported', 
  SUM(customer_total) AS 'total_revenue_generated', ROUND(AVG(customer_total), 2) AS 'average_revenue_per_customer'
  FROM employees JOIN total_avg_revenue
  ON employees.EmployeeId = total_avg_revenue.SupportRepId
  GROUP BY EmployeeId;

-- Intermediate Challenge

-- Do longer or shorter length albums tend to generate more revenue? 

WITH album_length AS
( SELECT albums.AlbumId, Title, SUM(Milliseconds)/1000/60 AS 'album_length_in_minutes', 
  CASE 
  WHEN SUM(Milliseconds)/1000/60 > 65 AND SUM(Milliseconds)/1000/60 <= 100
    THEN 'Long'
  WHEN SUM(Milliseconds)/1000/60 > 100 
    THEN 'Very Long'
  ELSE 'Short'
  END  'album_classification'
  FROM albums JOIN tracks
  ON albums.AlbumId = tracks.AlbumId
  GROUP BY albums.AlbumId
  ORDER BY 2 ASC
)
SELECT album_length.Title, album_length_in_minutes, album_classification, ROUND(SUM(Total), 2) AS 'total_album_revenue'
FROM album_length JOIN tracks
ON album_length.AlbumId = tracks.AlbumId
JOIN invoice_items
ON tracks.TrackId = invoice_items.TrackId
JOIN invoices
ON invoice_items.InvoiceId = invoices.InvoiceId
GROUP BY 2, 3
ORDER BY 4 DESC;

-- Is the number of times a track appear in any playlist a good indicator of sales? 
WITH track_count_in_playlist AS 
( SELECT Name, tracks.TrackId, COUNT(PlaylistId) AS 'count_in_playlist'
  FROM playlist_track JOIN tracks
  ON playlist_track.TrackId = tracks.TrackId
  GROUP BY 2
  ORDER BY 3
)
SELECT count_in_playlist, ROUND(AVG(Total), 2) AS 'average_revenue_by_track_count '
FROM track_count_in_playlist JOIN invoice_items
ON track_count_in_playlist.TrackId = invoice_items.TrackId
JOIN invoices
ON invoice_items.InvoiceId = invoices.InvoiceId
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;
WITH revenue as
( SELECT CAST(STRFTIME('%Y',InvoiceDate) as INT) AS 'Year', CAST(STRFTIME('%Y',InvoiceDate) as INT) - 1 AS 'Previous_Year', SUM(Total) AS 'Revenue_for_Year'
  FROM invoices
  GROUP BY 1
  ORDER BY 1 DESC
)
SELECT curr.Year, curr.Previous_Year, curr.Revenue_for_Year, ROUND((curr.Revenue_for_Year - prev.Revenue_for_Year)/prev.Revenue_for_Year * 1.0, 2) AS 'Pct_change_compared_to_last_year'
FROM revenue curr LEFT JOIN revenue prev
ON curr.Previous_Year = prev.Year;

