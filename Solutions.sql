-- Solutions for the Business Problems
// EASY LEVEL //
1. Find the total number of Movies and TV Shows.
   SELECT 
	        type,
          COUNT(*) As tot_count
   FROM netflix
   GROUP BY 1;

2. Get the Top 10 countries producing the most content.
   SELECT
	        country,
	        COUNT(*) As most_content
   FROM netflix
   WHERE country IS NOT NULL
   GROUP BY 1
   ORDER BY most_content DESC
   LIMIT 10;

3. Find the oldest and Newest content in each genre.
   SELECT 
         listed_in,
         MIN(release_year) AS oldest_year,
         MAX(release_year) AS newest_year
   FROM netflix
   GROUP BY listed_in
   ORDER BY oldest_year ASC, newest_year DESC;

4. Find the most frequent directors.
   SELECT 	directors, movie_count
   FROM(
	        SELECT
		            UNNEST(STRING_TO_ARRAY(director, ',')) As directors,
		            COUNT(*) As movie_count
	        FROM netflix
	        GROUP BY directors
  ) As t1
  ORDER BY movie_count DESC;

5. List all TV Shows added in last 5 years.
   SELECT title, date_added, release_year
   FROM netflix
   WHERE TO_DATE(date_added, 'Month DD, YYYY')>=CURRENT_DATE - INTERVAL '5year' AND type = 'TV Show';

// MEDIUM LEVEL //
6. Get the total number of shows added each month over the year.
   SELECT 
          EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS year,
          EXTRACT(MONTH FROM TO_DATE(date_added, 'Month DD, YYYY')) AS month,
          COUNT(*) AS total_added
   FROM netflix
   WHERE date_added IS NOT NULL
   GROUP BY year, month
   ORDER BY year DESC, month DESC;

7. Rank directors by the total number of shows they've directed with a ranking column.
   SELECT 	directors, movie_count, ranks
   FROM(
	        SELECT
		            UNNEST(STRING_TO_ARRAY(director, ',')) As directors,
		            COUNT(*) As movie_count,
		            rank() OVER(ORDER BY COUNT(*) DESC) as Ranks 
	        FROM netflix
	        GROUP BY directors
  ) As t1
  ORDER BY movie_count DESC, Ranks ASC;

8. Find the longest running TV Shows(in terms of Seasons) in each genre.
   SELECT title, duration
   FROM netflix
   WHERE type = 'TV Show' AND duration LIKE '%Seasons%'
   ORDER BY 
       SPLIT_PART(duration, ' ', 1)::INT DESC,
       title
   LIMIT 1;

9. Get the percentage of TV Shows and movies for each rating.
   SELECT 
         rating,
         type,
         COUNT(*) AS count,
         ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY type)), 2) AS percentage
   FROM netflix
   GROUP BY rating, type
   ORDER BY type, percentage DESC;

10. Find the countries with most content in each genre.
    WITH YearlyCountryContent AS (
    SELECT 
        release_year,
        country,
        COUNT(*) AS content_count
    FROM netflix
    WHERE country IS NOT NULL
    GROUP BY release_year, country
)
SELECT 
    release_year, 
    country, 
    content_count
FROM YearlyCountryContent
WHERE content_count = (
    SELECT MAX(content_count)
    FROM YearlyCountryContent AS inner_query
    WHERE inner_query.release_year = YearlyCountryContent.release_year
)
ORDER BY release_year DESC;

// DIFFICULT LEVEL //
11. Find the top 3 genre for each country.
    WITH GenreCounts AS (
    SELECT country,
           genre,
           COUNT(*) AS genre_count,
           ROW_NUMBER() OVER (PARTITION BY country ORDER BY COUNT(*) DESC) AS rank
    FROM (
        SELECT UNNEST(STRING_TO_ARRAY(country, ',')) AS country,  -- Split countries into rows
               UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS genre  -- Split genres into rows
        FROM netflix
    ) AS t1
    WHERE country IS NOT NULL AND genre IS NOT NULL
    GROUP BY country, genre
)
SELECT country,
       ARRAY_AGG(genre ORDER BY genre_count DESC) AS top_3_genres
FROM GenreCounts
WHERE rank <= 3
GROUP BY country
ORDER BY country;
  
12. Find the most popular genre.
    SELECT Genre_Group,
       COUNT(*) AS grouped_count
FROM (
    SELECT 
        -- Grouping genres into broader categories
        CASE 
            WHEN Genre IN ('Dramas', 'TV Dramas', 'Romantic TV Shows', 'Romantic Movies') THEN 'Drama'
            WHEN Genre IN ('Comedies', 'TV Comedies') THEN 'Comedy'
            WHEN Genre IN ('Action & Adventure', 'TV Action & Adventure') THEN 'Action & Adventure'
            WHEN Genre IN ('International Movies', 'International TV Shows') THEN 'International'
            WHEN Genre IN ('Documentaries', 'Docuseries') THEN 'Documentary'
            WHEN Genre IN ('Sci-Fi & Fantasy', 'TV Sci-Fi & Fantasy') THEN 'Sci-Fi & Fantasy'
            WHEN Genre IN ('Horror Movies', 'TV Horror') THEN 'Horror'
            WHEN Genre IN ('Crime TV Shows', 'Crime Movies') THEN 'Crime'
            WHEN Genre IN ('Kids'' TV', 'Children & Family Movies') THEN 'Family'
            ELSE Genre
        END AS Genre_Group
    FROM (
        SELECT UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS Genre
        FROM netflix
    ) AS t1
) AS t2
GROUP BY Genre_Group
ORDER BY grouped_count DESC;
  
13. Identify the country with the highest Average release year for content.
    WITH CountrySplit AS (
    SELECT UNNEST(STRING_TO_ARRAY(country, ',')) AS country, release_year
    FROM netflix
    WHERE release_year IS NOT NULL
),
CountryAverages AS (
    SELECT country, AVG(release_year) AS avg_release_year,
	rank() OVER (ORDER BY AVG(release_year) DESC) As rnk
    FROM CountrySplit
    GROUP BY country
)
SELECT country, avg_release_year, rnk
FROM CountryAverages
LIMIT 1;
  
14. Find the Top 5 countries by their contribution to specific gentre.
    SELECT 
    listed_in AS genre,
    country,
    COUNT(*) AS total_shows
FROM netflix
WHERE listed_in LIKE '%Drama%' AND country IS NOT NULL
GROUP BY genre, country
ORDER BY total_shows DESC
LIMIT 5;

  
15. Identify the casts members who appear in most content.
    WITH SplitCast AS (
    SELECT 
        show_id, 
        type, 
        UNNEST(STRING_TO_ARRAY(casts, ',')) AS cast_member
    FROM netflix
)
SELECT 
    cast_member,
    COUNT(*) AS appearances
FROM SplitCast
WHERE cast_member IS NOT NULL
GROUP BY cast_member
ORDER BY appearances DESC
LIMIT 10;
