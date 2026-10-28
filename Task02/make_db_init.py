import csv
import re
import os


SQL_FILE = 'db_init.sql'

DATASET_DIR = 'dataset'

def escape_sql_string(val):

    if val is None:
        return 'NULL'
    return "'" + str(val).replace("'", "''") + "'"

def generate_sql():
    with open(SQL_FILE, 'w', encoding='utf-8') as f:

        f.write("DROP TABLE IF EXISTS movies;\n")
        f.write("DROP TABLE IF EXISTS ratings;\n")
        f.write("DROP TABLE IF EXISTS tags;\n")
        f.write("DROP TABLE IF EXISTS users;\n\n")


        f.write("CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT, year INTEGER, genres TEXT);\n")
        f.write("CREATE TABLE ratings (id INTEGER PRIMARY KEY, user_id INTEGER, movie_id INTEGER, rating REAL, timestamp INTEGER);\n")
        f.write("CREATE TABLE tags (id INTEGER PRIMARY KEY, user_id INTEGER, movie_id INTEGER, tag TEXT, timestamp INTEGER);\n")
        f.write("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT, gender TEXT, register_date TEXT, occupation TEXT);\n\n")


        movies_path = os.path.join(DATASET_DIR, 'movies.csv')
        if os.path.exists(movies_path):
            with open(movies_path, 'r', encoding='utf-8') as mf:
                reader = csv.reader(mf)
                next(reader, None)  # Пропускаем заголовок
                for row in reader:
                    if len(row) >= 3:
                        movie_id, title, genres = row[0], row[1], row[2]
                        year = 'NULL'

                        match = re.search(r'\((\d{4})\)$', title)
                        if match:
                            year = match.group(1)
                        f.write(f"INSERT INTO movies (id, title, year, genres) VALUES ({movie_id}, {escape_sql_string(title)}, {year}, {escape_sql_string(genres)});\n")
            f.write("\n")


        ratings_path = os.path.join(DATASET_DIR, 'ratings.csv')
        if os.path.exists(ratings_path):
            with open(ratings_path, 'r', encoding='utf-8') as rf:
                reader = csv.reader(rf)
                next(reader, None)
                for i, row in enumerate(reader, start=1):
                    if len(row) >= 4:
                        user_id, movie_id, rating, timestamp = row[0], row[1], row[2], row[3]
                        f.write(f"INSERT INTO ratings (id, user_id, movie_id, rating, timestamp) VALUES ({i}, {user_id}, {movie_id}, {rating}, {timestamp});\n")
            f.write("\n")


        tags_path = os.path.join(DATASET_DIR, 'tags.csv')
        if os.path.exists(tags_path):
            with open(tags_path, 'r', encoding='utf-8') as tf:
                reader = csv.reader(tf)
                next(reader, None)
                for i, row in enumerate(reader, start=1):
                    if len(row) >= 4:
                        user_id, movie_id, tag, timestamp = row[0], row[1], row[2], row[3]
                        f.write(f"INSERT INTO tags (id, user_id, movie_id, tag, timestamp) VALUES ({i}, {user_id}, {movie_id}, {escape_sql_string(tag)}, {timestamp});\n")
            f.write("\n")


        users_path = os.path.join(DATASET_DIR, 'users.csv')
        if os.path.exists(users_path):
            with open(users_path, 'r', encoding='utf-8') as uf:
                reader = csv.reader(uf)
                next(reader, None)
                for row in reader:
                    if len(row) >= 6:
                        # Ожидаемый порядок: id, name, email, gender, register_date, occupation
                        id_val, name, email, gender, reg_date, occupation = row[0], row[1], row[2], row[3], row[4], row[5]
                        f.write(f"INSERT INTO users (id, name, email, gender, register_date, occupation) VALUES ({id_val}, {escape_sql_string(name)}, {escape_sql_string(email)}, {escape_sql_string(gender)}, {escape_sql_string(reg_date)}, {escape_sql_string(occupation)});\n")
            f.write("\n")

if __name__ == '__main__':
    generate_sql()
    print(f"Файл {SQL_FILE} успешно сгенерирован.")