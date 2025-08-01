# Mini Sales Dashboard with Snowflake & Streamlit

A mini sales dashboard built with Snowflake and Streamlit. This project demonstrates data modeling, efficient SQL querying, and building an interactive front-end for data visualization.

---

### Key Features

- **Snowflake Backend**: Data is loaded, transformed, and modeled into a Star Schema directly within Snowflake.
- **Analytical SQL Queries**: Includes queries to calculate KPIs like YoY growth, revenue by category, and top-performing products.
- **Interactive Dashboard**: A Streamlit front-end provides:
    - Filters for product category and date range.
    - KPI cards for Total Revenue, Units Sold, and Unique Customers.
    - A dynamic bar chart showing revenue by brand.
- **Secure Connection**: Uses Streamlit's secrets management to handle Snowflake credentials safely.
- **Data Export**: A download button to export the filtered data as a CSV file.

---

### Project Architecture

The project follows a simple, three-layer architecture to separate data storage, transformation, and presentation.

**`[Raw CSV Files]`** → **`[Snowflake: Staging Tables]`** → **`[Snowflake: Star Schema]`** → **`[Streamlit App]`**

1.  **Data Ingestion**: Raw data from `sales.csv` and `products.csv` is loaded into staging tables (`raw_sales`, `raw_products`) in Snowflake. These tables are a direct copy of the source files.

2.  **Data Modeling**: The `setup.sql` script transforms the raw data from the staging tables into a clean, performant **Star Schema**. This schema, consisting of a central `fact_sales` table and multiple `dim_` tables, serves as the single source of truth for all analysis.

3.  **Data Presentation**: The Streamlit application (`app.py`) connects directly to the final Star Schema tables in Snowflake. It runs SQL queries to fetch aggregated data and presents it visually through interactive charts, filters, and KPI metrics. The app never interacts with the raw data files.

---

### Technologies Used

- **Data Warehouse**: Snowflake
- **Data Transformation**: SQL
- **Dashboarding**: Python with Streamlit
- **Data Handling**: Pandas

---

### Repository Structure

```
.
├── .streamlit/
│   └── secrets.toml    # Snowflake credentials (ignored by git)
├── data/
│   ├── products.csv
│   └── sales.csv
├── sql/
│   ├── setup.sql             # DDL/DML for database modeling
│   └── analytical_queries.sql # Queries used by the app
├── .gitignore
├── app.py                # Main Streamlit application code
├── requirements.txt
└── README.md
```

---

### Setup and Installation

To run this project locally, follow these steps:

**1. Clone the Repository**
```bash
git clone <your-repository-url>
cd <repository-name>
```

**2. Install Python Dependencies**
```bash
pip install -r requirements.txt
```

**3. Configure Snowflake Credentials**

Create a folder named `.streamlit` and a file inside it named `secrets.toml`. Add your Snowflake credentials to this file. See `app.py` for required fields.

**4. Set up the Database**

Log in to your Snowflake account and run the entire `sql/setup.sql` script in a worksheet to create and populate all necessary tables.

**5. Run the Streamlit App**
```bash
streamlit run app.py
```

---

### Potential Improvements

Given more time, the following improvements could be made:

- **Incremental Data Loading**: Implement a more robust ETL process (e.g., using MERGE or Snowpipe) that only loads new or updated data.
- **Data Quality Tests**: Add tests to validate the source data and ensure model integrity (e.g., using dbt).
- **Expanded Dimensions**: Create a more detailed `dim_customer` to enable analysis of customer behavior.