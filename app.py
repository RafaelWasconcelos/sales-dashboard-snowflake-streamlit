import streamlit as st
import pandas as pd
from snowflake.connector import connect

# ======================================================================================
# Page Configuration
# ======================================================================================

st.set_page_config(
    page_title="Mini Sales Dashboard",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ======================================================================================
# Snowflake Connection and Data Loading (with Caching)
# ======================================================================================

# This function establishes a connection to Snowflake and runs a query.
# The @st.cache_data decorator caches the query results for 10 minutes (ttl=600s),
# making the app much faster by avoiding redundant database calls.
@st.cache_data(ttl=600)
def run_query(query):
    """Connects to Snowflake and returns the query results as a Pandas DataFrame."""
    conn = connect(**st.secrets.snowflake)
    cursor = conn.cursor()
    cursor.execute(query)
    df = cursor.fetch_pandas_all()
    cursor.close()
    conn.close()
    return df

# ======================================================================================
# Main Application
# ======================================================================================

st.title("📊 Mini Sales Dashboard")
st.markdown("An interactive dashboard connected to a Snowflake sales database.")

# --- Load data from Snowflake ---
# We run a single, comprehensive query to get all the data we need.
# Joining the tables in SQL is more efficient than merging in Pandas.
try:
    query = """
    SELECT
        s.DATE_KEY,
        s.UNITS_SOLD,
        s.TOTAL_REVENUE,
        s.CUSTOMER_ID,
        p.CATEGORY,
        p.BRAND
    FROM fact_sales s
    JOIN dim_product p ON s.product_key = p.product_key;
    """
    main_df = run_query(query)

    # Convert date column to datetime objects for filtering
    main_df['DATE_KEY'] = pd.to_datetime(main_df['DATE_KEY'])

except Exception as e:
    st.error(f"An error occurred while loading data: {e}")
    st.info("Please check your Snowflake credentials and database setup.")
    st.stop() # Stop the app if data loading fails

# ======================================================================================
# Sidebar Filters
# ======================================================================================

st.sidebar.header("Dashboard Filters")

# --- Category Filter ---
all_categories = main_df['CATEGORY'].unique()
selected_categories = st.sidebar.multiselect(
    "Select Product Category",
    options=all_categories,
    default=all_categories  # Select all by default
)

# --- Date Range Filter ---
min_date = main_df['DATE_KEY'].min().date()
max_date = main_df['DATE_KEY'].max().date()

selected_date_range = st.sidebar.date_input(
    "Select Date Range",
    value=(min_date, max_date),
    min_value=min_date,
    max_value=max_date
)

# Convert the selected date range tuple into start and end dates
start_date = pd.to_datetime(selected_date_range[0])
end_date = pd.to_datetime(selected_date_range[1])

# --- Applying Filters ---
filtered_df = main_df[
    (main_df['CATEGORY'].isin(selected_categories)) &
    (main_df['DATE_KEY'].between(start_date, end_date))
]

# Stop the app if the filters result in no data, to avoid errors
if filtered_df.empty:
    st.warning("No data available for the selected filters.")
    st.stop()

# ======================================================================================
# Main Page Display
# ======================================================================================

# --- KPI Metric Cards ---
total_revenue = filtered_df['TOTAL_REVENUE'].sum()
total_units_sold = filtered_df['UNITS_SOLD'].sum()
unique_customers = filtered_df['CUSTOMER_ID'].nunique()

# Use st.columns to arrange the KPIs side-by-side
col1, col2, col3 = st.columns(3)
col1.metric("Total Revenue", f"${total_revenue:,.2f}")
col2.metric("Total Units Sold", f"{total_units_sold:,}")
col3.metric("Unique Customers", f"{unique_customers:,}")

st.markdown("---") # Visual separator

# --- Bar Chart: Revenue by Brand ---
st.header("Revenue by Brand")
brand_revenue = filtered_df.groupby('BRAND')['TOTAL_REVENUE'].sum().sort_values(ascending=False)
st.bar_chart(brand_revenue)

# --- Bonus: Download Button ---
# A helper function to convert the DataFrame to CSV format for download
@st.cache_data
def convert_df_to_csv(df):
    return df.to_csv(index=False).encode('utf-8')

st.download_button(
    label="Download Filtered Data as CSV",
    data=convert_df_to_csv(filtered_df),
    file_name='filtered_sales_data.csv',
    mime='text/csv',
)