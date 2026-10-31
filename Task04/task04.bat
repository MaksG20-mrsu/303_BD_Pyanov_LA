#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма, который они ценили. В списке оставить первые 100 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
SELECT u1.name AS user1, u2.name AS user2, m.title 
FROM ratings r1 
JOIN ratings r2 ON r1.movie_id = r2.movie_id 
JOIN users u1 ON r1.user_id = u1.id 
JOIN users u2 ON r2.user_id = u2.id 
JOIN movies m ON r1.movie_id = m.id 
WHERE r1.user_id < r2.user_id 
LIMIT 100;"
echo " "

echo "2. Найти 10 самых свежих оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
SELECT m.title, u.name, r.rating, date(r.timestamp, 'unixepoch') AS rating_date 
FROM ratings r 
JOIN movies m ON r.movie_id = m.id 
JOIN users u ON r.user_id = u.id 
GROUP BY r.user_id 
ORDER BY r.timestamp DESC 
LIMIT 10;"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке 'Рекомендуем' для фильмов должно быть написано 'Да' или 'Нет'."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH MovieStats AS (
    SELECT movie_id, AVG(rating) as avg_rating
    FROM ratings
    GROUP BY movie_id
),
MinMax AS (
    SELECT MAX(avg_rating) as max_r, MIN(avg_rating) as min_r FROM MovieStats
)
SELECT m.title, m.year, ms.avg_rating,
       CASE WHEN ms.avg_rating = (SELECT max_r FROM MinMax) THEN 'Да' ELSE 'Нет' END AS Recommend
FROM MovieStats ms
JOIN movies m ON ms.movie_id = m.id
WHERE ms.avg_rating = (SELECT max_r FROM MinMax) OR ms.avg_rating = (SELECT min_r FROM MinMax)
ORDER BY m.year ASC, m.title ASC;"
echo " "

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-женщины в период с 2010 по 2012 год."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
SELECT COUNT(r.id) AS total_ratings, AVG(r.rating) AS avg_rating 
FROM ratings r 
JOIN users u ON r.user_id = u.id 
WHERE u.gender = 'F' 
  AND date(r.timestamp, 'unixepoch') BETWEEN '2010-01-01' AND '2012-12-31';"
echo " "

echo "5. Составить список фильмов с указанием их средней оценки и места в рейтинге по средней оценке. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH RankedMovies AS (
    SELECT m.title, m.year, AVG(r.rating) AS avg_rating,
           RANK() OVER (ORDER BY AVG(r.rating) DESC) as rating_rank
    FROM movies m
    JOIN ratings r ON m.id = r.movie_id
    GROUP BY m.id
)
SELECT title, year, avg_rating, rating_rank 
FROM RankedMovies 
ORDER BY year ASC, title ASC 
LIMIT 20;"
echo " "

echo "6. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации' (сначала фамилия, потом имя)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
SELECT 
    CASE 
        WHEN instr(name, ' ') > 0 THEN substr(name, instr(name, ' ') + 1) || ' ' || substr(name, 1, instr(name, ' ') - 1)
        ELSE name 
    END AS formatted_name,
    register_date
FROM users 
ORDER BY register_date DESC 
LIMIT 10;"
echo " "

echo "7. С помощью рекурсивного CTE составить таблицу умножения для чисел от 1 до 10. Должен получиться один столбец следующего вида:"
echo "1x1=1 ... 10x10=100"
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE 
  num(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM num WHERE x < 10),
  mult(a, b) AS (
    SELECT x, 1 FROM num
    UNION ALL
    SELECT a, b+1 FROM mult WHERE b < 10
  )
SELECT a || 'x' || b || '=' || (a*b) AS multiplication_table
FROM mult
ORDER BY a, b;"
echo " "

echo "8. С помощью рекурсивного CTE выделить все жанры фильмов, имеющиеся в таблице movies (каждый жанр в отдельной строке)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE split_genres(id, genre, rest) AS (
  SELECT id, '', genres || '|' FROM movies
  UNION ALL
  SELECT id, substr(rest, 0, instr(rest, '|')), substr(rest, instr(rest, '|') + 1) 
  FROM split_genres 
  WHERE rest <> ''
)
SELECT DISTINCT genre 
FROM split_genres 
WHERE genre <> '' 
ORDER BY genre;"
echo " "