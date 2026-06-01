# wallmart_sales_analysis_using_Python_MySql

## 📌 Project Overview

This is an end-to-end data analysis project designed to extract critical business insights from Walmart sales data. The project uses **Python** for data cleaning and pipeline creation, and **MySQL** for advanced SQL querying and business problem solving.

<img width="1162" height="607" alt="image" src="https://github.com/user-attachments/assets/2b9eeac0-c93c-486d-9ae0-766ee67d5d92" />



> **Tools Used:** Python 3.10 | Pandas | SQLAlchemy | PyMySQL | MySQL Workbench

---

## 📁 Project Structure

```
walmart-sales-analysis/
│
├── data/
│   └── Walmart.csv                  # Raw dataset from Kaggle
│
├── notebooks/
│   └── walmart.ipynb                # Jupyter Notebook — data cleaning & loading
│
├── sql_queries/
│   └── walmart_queries.sql          # All MySQL business queries
│
├── README.md                        # Project documentation
└── requirements.txt                 # Python dependencies
```

---

## 📦 Dataset

- **Source:** Kaggle — Walmart Sales Dataset
- **Raw Records:** 10,051
- **Final Clean Records:** 9,969
- **Columns:** invoice_id, Branch, City, category, unit_price, quantity, date, time, payment_method, rating, profit_margin

---

## ⚙️ Requirements

```
pandas
numpy
sqlalchemy
pymysql
```

Install all dependencies:
```bash
pip install pandas numpy sqlalchemy pymysql
```

---

## 🐍 Python — Data Cleaning Steps

### Step 1: Load the Data

```python
import pandas as pd

df = pd.read_csv("data/Walmart.csv")

print(df.shape)    # (10051, 11)
print(df.head())
print(df.columns)
```

**Output:**
```
(10051, 11)
Columns: invoice_id, Branch, City, category, unit_price,
         quantity, date, time, payment_method, rating, profit_margin
```

---

### Step 2: Data Exploration

```python
# Statistical summary
df.describe()

# Data types and null counts
df.info()
```

**Key observations from `.info()`:**
- `unit_price` — object type (has `$` symbol, needs cleaning)
- `quantity` — float64 (has 31 missing values)
- All other columns — no nulls

---

### Step 3: Remove Duplicates

```python
# Check duplicates
print(df.duplicated().sum())   # 51 duplicates found

# Remove duplicates
df.drop_duplicates(inplace=True)

# Verify
print(df.duplicated().sum())   # 0
print(df.shape)                # (10000, 11)
```

---

### Step 4: Handle Missing Values

```python
# Check nulls per column
df.isnull().sum()
```

**Result:**
```
unit_price     31
quantity       31
(all others)    0
```

```python
# Drop rows with missing values
df.dropna(inplace=True)

# Verify
df.isnull().sum()   # All 0
print(df.shape)     # (9969, 11)
```

---

### Step 5: Fix Data Types — Remove `$` from unit_price

```python
# unit_price was stored as object with $ symbol
df['unit_price'] = df['unit_price'].str.replace('$', '').astype(float)

# Verify
df.dtypes
```

**Before:** `unit_price → object ($74.69)`
**After:** `unit_price → float64 (74.69)`

---

### Step 6: Feature Engineering — Create `total` Column

```python
# Calculate total transaction amount
df['total'] = df['unit_price'] * df['quantity']

# Verify
df.head()
```

**Sample output:**
```
invoice_id  unit_price  quantity   total
1           74.69       7.0        522.83
2           15.28       5.0        76.40
3           46.33       7.0        324.31
```

---

### Step 7: Final Data Check

```python
df.info()
```

**Clean dataset summary:**
```
Records    : 9,969
Columns    : 12 (11 original + 1 engineered: total)
Nulls      : 0
Duplicates : 0
unit_price : float64 ✅
quantity   : float64 ✅
total      : float64 ✅
```

---

### Step 8: Load Data into MySQL

```python
import pymysql
from sqlalchemy import create_engine

# Create MySQL connection
engine_mysql = create_engine(
    "mysql+pymysql://root:root@localhost:3306/walmart_db"
)

try:
    engine_mysql
    print("connection successed to mysql")
except:
    print("Unable to connect")

# Load cleaned dataframe into MySQL
df.to_sql(
    name='walmart',
    con=engine_mysql,
    if_exists='append',
    index=False
)
# Output: 9969 rows loaded ✅
```

---

## 🗄️ MySQL — Business Problems & Queries

### Exploratory Queries

```sql
-- View all records
SELECT * FROM walmart;

-- Total record count
SELECT COUNT(*) FROM walmart;

-- Payment method distribution
SELECT payment_method, COUNT(*) AS count
FROM walmart
GROUP BY payment_method
ORDER BY count DESC;

-- Distinct branches
SELECT COUNT(DISTINCT branch) FROM walmart;

-- Quantity range
SELECT MIN(quantity), MAX(quantity) FROM walmart;
```

---

### Q1: Payment methods, number of transactions, and quantity sold

```sql
SELECT
    payment_method,
    COUNT(*)       AS number_of_payments,
    SUM(quantity)  AS no_of_quantity_sold
FROM walmart
GROUP BY payment_method;
```

---

### Q2: Highest-rated category in each branch

```sql
WITH cte AS (
    SELECT
        branch,
        category,
        AVG(rating)  AS avg_rating,
        DENSE_RANK() OVER (PARTITION BY branch ORDER BY AVG(total) DESC) AS rnk
    FROM walmart
    GROUP BY branch, category
)
SELECT * FROM cte
WHERE rnk = 1;
```

---

### Q3: Busiest day for each branch based on number of transactions

```sql
WITH cte AS (
    SELECT
        branch,
        DAYNAME(STR_TO_DATE(date, '%d/%m/%y')) AS day_name,
        COUNT(*)                               AS no_transaction,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart
    GROUP BY branch, day_name
)
SELECT * FROM cte
WHERE rnk = 1;
```

---

### Q4: Total quantity of items sold per payment method

```sql
SELECT
    payment_method,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method
ORDER BY no_qty_sold DESC;
```

---

### Q5: Average, minimum, and maximum rating by city and category

```sql
SELECT
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM walmart
GROUP BY city, category;
```

---

### Q6: Total profit for each category

```sql
SELECT
    category,
    ROUND(SUM(total), 2)               AS total_revenue,
    ROUND(SUM(total * profit_margin), 2) AS profit
FROM walmart
GROUP BY category
ORDER BY profit DESC;
```

---

### Q7: Most common payment method for each branch

```sql
WITH cte AS (
    SELECT
        branch,
        payment_method,
        COUNT(*)   AS total_txn,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT * FROM cte
WHERE rnk = 1;
```

---

### Q8: Sales by Morning, Afternoon, and Evening shifts

```sql
SELECT
    CASE
        WHEN HOUR(time) < 12            THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END          AS shift,
    COUNT(*)     AS number_of_txn
FROM walmart
GROUP BY shift
ORDER BY number_of_txn DESC;
```

---

### Q9: Top 5 branches with highest revenue decrease ratio (2022 vs 2023)

```sql
WITH cte1 AS (
    SELECT branch, SUM(total) AS revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%y')) = 2022
    GROUP BY branch
),
cte2 AS (
    SELECT branch, SUM(total) AS revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%y')) = 2023
    GROUP BY branch
)
SELECT
    branch,
    c1.revenue                                        AS rev_2022,
    c2.revenue                                        AS rev_2023,
    ROUND((c1.revenue - c2.revenue) / c1.revenue * 100, 2) AS rev_dec_ratio
FROM cte1 c1
JOIN cte2 c2 USING (branch)
WHERE c1.revenue > c2.revenue
ORDER BY rev_dec_ratio DESC
LIMIT 5;
```

---

### Q10: Highest revenue branch-category combination each year

```sql
WITH cte AS (
    SELECT
        branch,
        category,
        YEAR(STR_TO_DATE(date, '%d/%m/%Y')) AS yr,
        ROUND(SUM(total), 2)                AS revenue,
        RANK() OVER (
            PARTITION BY YEAR(STR_TO_DATE(date, '%d/%m/%Y'))
            ORDER BY SUM(total) DESC
        ) AS rnk
    FROM walmart
    GROUP BY branch, category, yr
)
SELECT yr, branch, category, revenue
FROM cte
WHERE rnk = 1
ORDER BY yr;
```

**Result:**
```
yr   | branch  | category            | revenue
2019 | WALM066 | Home and lifestyle  | 3691.22
2020 | WALM058 | Fashion accessories | 3355.00
2021 | WALM009 | Home and lifestyle  | 3758.00
2022 | WALM029 | Home and lifestyle  | 3010.00
2023 | WALM038 | Fashion accessories | 3335.00
```

---

### Q11: Best-selling categories ranked by revenue

```sql
SELECT
    category,
    SUM(quantity)           AS total_qty_sold,
    ROUND(SUM(total), 2)    AS total_revenue,
    ROUND(AVG(rating), 2)   AS avg_rating,
    COUNT(*)                AS total_transactions,
    RANK() OVER (ORDER BY SUM(total) DESC) AS revenue_rank
FROM walmart
GROUP BY category
ORDER BY revenue_rank;
```

**Result:**
```
category              | total_qty_sold | total_revenue | avg_rating | total_txn | rank
Fashion accessories   | 9653           | 489480.90     | 5.78       | 4538      | 1
Home and lifestyle    | 9610           | 489250.06     | 5.74       | 4520      | 2
Electronic accessories| 1494           | 78175.03      | 5.91       | 419       | 3
Food and beverages    | 952            | 53471.28      | 7.11       | 174       | 4
Sports and travel     | 920            | 52497.93      | 6.92       | 166       | 5
Health and beauty     | 854            | 46851.18      | 7.00       | 152       | 6
```

---

### Q12: City + Shift + Payment method performance breakdown

```sql
SELECT
    city,
    CASE
        WHEN HOUR(time) < 12            THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END                      AS shift,
    payment_method,
    COUNT(*)                 AS total_transactions,
    ROUND(SUM(total), 2)     AS total_revenue,
    ROUND(AVG(rating), 2)    AS avg_rating
FROM walmart
GROUP BY city, shift, payment_method
ORDER BY city, total_revenue DESC;
```

---

### Q13: Peak sales shift, day, and month with customer spending pattern

```sql
SELECT
    YEAR(STR_TO_DATE(date, '%d/%m/%Y'))      AS yr,
    MONTHNAME(STR_TO_DATE(date, '%d/%m/%Y')) AS month_name,
    DAYNAME(STR_TO_DATE(date, '%d/%m/%Y'))   AS day_name,
    CASE
        WHEN HOUR(time) < 12            THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END                                      AS shift,
    COUNT(*)                                 AS total_transactions,
    ROUND(SUM(total), 2)                     AS total_revenue,
    ROUND(AVG(total), 2)                     AS avg_spend_per_txn,
    ROUND(AVG(quantity), 2)                  AS avg_qty_per_txn
FROM walmart
GROUP BY yr, month_name, day_name, shift
ORDER BY total_revenue DESC
LIMIT 10;
```

**Top Result:**
```
2019 | March | Saturday | Afternoon | 36 txns | 14425.61 revenue | 400.71 avg spend
```

---

## 📊 Key Findings

### Category Performance
- **Fashion Accessories** and **Home and Lifestyle** are top revenue drivers (~489K each) — nearly equal competition
- **Food & Beverages** has the highest avg rating (7.11) but lowest transactions (174) — high satisfaction, low reach *(hidden gem)*
- **Electronic Accessories** ranks 3rd in revenue (78K) with decent avg rating (5.91)

### Branch & Yearly Trends
- **Home and Lifestyle** dominated branch-level revenue in 2019, 2021, and 2022
- **Fashion Accessories** took the top spot in 2020 and 2023
- No single branch dominates consistently year over year
- **WALM029** (2022) and **WALM038** (2023) are the most recent top performers

### Time & Shift Patterns
- **Afternoon shift (12PM–5PM)** dominates ALL top 10 peak sales periods
- **Saturday + Afternoon** = highest revenue combination overall
- **2019 March Saturday Afternoon** = all-time peak (revenue: 14,425.61)
- **January and March** repeat frequently — seasonal buying surge is predictable

### Payment & City Insights
- **Ewallet** is the most preferred payment method across all cities
- **Evening + Ewallet** combo is strongest (observed in Abilene data)
- Cash transactions are minimal — digital payments dominate

---

## 💡 Recommendations

| Area | Recommendation |
|------|----------------|
| **Inventory** | Invest heavily in Fashion Accessories & Home and Lifestyle — combined ~978K revenue |
| **Hidden Gem** | Aggressively promote Food & Beverages — highest rated (7.11) but underutilized |
| **Staffing** | Deploy more staff during Afternoon shift (12PM–5PM), especially on Saturdays |
| **Stock Planning** | Plan advance stock for January and March — seasonal surges are predictable |
| **Payments** | Offer Ewallet loyalty rewards to retain dominant payment users |
| **Branch Strategy** | Replicate WALM029 & WALM038 strategies in underperforming branches |
| **Evening Push** | Launch Ewallet cashback offers in Evening shift — strong combo observed |

---

## 🏆 Final Insight

> *"Analysis reveals Afternoon shift drives peak sales, Fashion Accessories & Home and Lifestyle lead revenue, while Food & Beverages shows untapped growth potential despite achieving the highest customer satisfaction ratings."*

---

## 🔮 Future Enhancements

- Integration with **Power BI / Tableau** for interactive dashboards
- **Real-time data pipeline** using Apache Kafka or Airflow
- **PostgreSQL** version of all queries for cross-database compatibility
- Predictive modeling for **demand forecasting** by category and season
