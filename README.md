## html_to_strapi_json PostgreSQL Function

This repository provides a PostgreSQL function that converts HTML content into a JSON format compatible with Strapi's Slate editor. The function is written in PL/Python (plpython3u) and uses BeautifulSoup for HTML parsing.

### Dependencies

 PostgreSQL with PL/Python enabled (plpython3u)
- Python module BeautifulSoup

Install BeautifulSoup in the environment used by PostgreSQL. For example:
```bash
pip install beautifulsoup4
```

### Installation

 1. Enable PL/Python in your PostgreSQL database:
```bash
CREATE EXTENSION IF NOT EXISTS plpython3u;
```
 2. Create the function by running the SQL script:

```bash
psql -d database_name -f html_to_strapi_json.sql
```
(or run it as a query on pgAdmin)

### Usage

You can test the function directly:

```bash
SELECT html_to_strapi_json('<p>Hello, world!</p>');
```

This will produce the following output:

```json
[
  {
    "type": "paragraph",
    "children": [
      {
        "text": "Hello, world!",
        "type": "text"
      }
    ]
  }
]
```

To convert existing HTML rich text fields in Strapi to Slate JSON (and change the field type to `jsonb`), run the `convert.sql` script. This script will iterate through the HTML fields and perform the conversion.
