import pandas as pd
import os


def format_value(value, column_type):
    if pd.isna(value):
        return "NULL"
    elif column_type == "int64":
        return str(int(value))
    elif column_type == "float64":
        return str(float(value))
    elif column_type == "object":
        return f'"{value}"'
    else:
        return f'"{value}"'


# Read CSV file into a pandas DataFrame
csv_file_path = "E:/wiscl/Documents/projects_da/supply_chain_v2_sql/csv_files/Tables/Customers.csv"  # Replace with your CSV file path
df = pd.read_csv(csv_file_path, encoding="utf-8")

# Specify the table name
table_name = os.path.splitext(os.path.basename(csv_file_path))[0]

# Generate SQL insert statements
sql_statements = []
for _, row in df.iterrows():
    columns = ", ".join(row.index)
    values = ", ".join(
        format_value(val, col_type) for val, col_type in zip(row.values, df.dtypes)
    )
    sql_insert = f"INSERT INTO {table_name} ({columns}) VALUES ({values});"
    sql_statements.append(sql_insert)

# Write SQL statements to a file
sql_output_file = (
    "E:/wiscl/Documents/projects_da/supply_chain_v2_sql/csv_files/"
    + table_name
    + ".sql"
)  # Replace with your desired output file path
with open(sql_output_file, "w", encoding="utf-8") as f:
    f.write("\n".join(sql_statements))

print(f"SQL insert statements have been written to {sql_output_file}")
