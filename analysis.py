import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates


df = pd.read_csv('Airline_Delay_Cause2020_2025.csv')
missing_any = df[df.isnull().any(axis=1)].copy()
print(df.describe())

print(df.isnull().sum()) #many columns are missing 261 values, but the arr_del15 column is missing 497 values

print(df.isnull().any(axis=1).sum()) #497 rows with missing values
#trying to check for trends/patterns among the missing values 
#for example, maybe one particular carrier or airport isn't reporting their data
#print(missing_any.shape)

# among the rows with any missing value, count carriers
missing_any["carrier_name"].value_counts().head(20)
#Missing: Allegient Air: 63, Mes Airlines Inc.: 46, Skywest Airlines Inc: 46, Delta Air Lines Network:36,
#certain companies are missing more than others

# among the rows with any missing value, count airports
missing_any["airport"].value_counts().head(20)
#no airport has more than 10 missing rows

print(missing_any["month"].value_counts().head(12))
#most of rows w missing values are from 2020 (has 6x has many as 2021 which has 2nd most missing). 2020 has 338 missing
print(missing_any["year"].value_counts().head(6))
#most of rows w missing values are from april (has 5x has many as october which has 2nd most missing). April has 229 missing

missing_2020 = missing_any[missing_any["year"] == 2020]

print(
    missing_2020["month"]
        .value_counts()
        .sort_index()
)

#217 of the 497 rows with missing values are from april 2020 (has 217 missing)

print(df[df["year"]==2020]["month"].value_counts().sort_index())
# april 2020 has 1912 total rows
#April 2020 was a tumultuous time, so I'm going to drop that entirely from the data
#also going to drop rows that are missing arr_delays and arr_flights, which I need to make average delay per flight
key_cols = ["arr_flights", "arr_delay"]
df_outcome_possible = df.dropna(subset=key_cols).copy()

df_2021plus = df_outcome_possible[df_outcome_possible["year"] >= 2021].copy()

#airports with most flight
airport_totals = (df_2021plus
                  .groupby("airport", as_index=False)["arr_flights"]
                  .sum()
                  .sort_values("arr_flights", ascending=False))

top_airports = airport_totals["airport"].head(5).tolist()
print("Top airports:", top_airports)

airport_monthly = (df_2021plus[df_2021plus["airport"].isin(top_airports)]
                   .groupby(["year", "month", "airport"], as_index=False)
                   .agg({"arr_flights": "sum",
                         "arr_delay": "sum"}))

airport_monthly["avg_delay_per_flight"] = (
    airport_monthly["arr_delay"] / airport_monthly["arr_flights"]
)

airport_monthly["date"] = pd.to_datetime(dict(
    year=airport_monthly["year"],
    month=airport_monthly["month"],
    day=1
))

plt.figure(figsize=(10,6))

for ap in top_airports:
    temp = airport_monthly[airport_monthly["airport"] == ap]
    plt.plot(temp["date"], temp["avg_delay_per_flight"], label=ap)

plt.title("Monthly Avg Arrival Delay per Flight by Airport 2021–2025")
plt.xlabel("Month")
plt.ylabel("Avg delay per flight (minutes)")
plt.grid(True)
plt.legend(title="Airport")
plt.tight_layout()
plt.savefig("avg_delay_top5_airports_2021_2025.png")



#carriers with most flights
carrier_totals = (df_2021plus
                  .groupby("carrier_name", as_index=False)["arr_flights"]
                  .sum()
                  .sort_values("arr_flights", ascending=False))

top_carriers = carrier_totals["carrier_name"].head(5).tolist()
print("Top carriers:", top_carriers)

carrier_monthly = (df_2021plus[df_2021plus["carrier_name"].isin(top_carriers)]
                   .groupby(["year", "month", "carrier_name"], as_index=False)
                   .agg({"arr_flights": "sum",
                         "arr_delay": "sum"}))

carrier_monthly["avg_delay_per_flight"] = (
    carrier_monthly["arr_delay"] / carrier_monthly["arr_flights"]
)

carrier_monthly["date"] = pd.to_datetime(dict(
    year=carrier_monthly["year"],
    month=carrier_monthly["month"],
    day=1
))

plt.figure(figsize=(10,6))

for carrier in top_carriers:
    temp = carrier_monthly[carrier_monthly["carrier_name"] == carrier]
    plt.plot(temp["date"], temp["avg_delay_per_flight"], label=carrier)

plt.title("Monthly Avg Arrival Delay per Flight by Carrier (2021–2025)")
plt.xlabel("Month")
plt.ylabel("Avg delay per flight (minutes)")
plt.grid(True)
plt.legend(title="Carrier")
plt.tight_layout()
plt.savefig("avg_delay_top5_carriers_2021_2025.png")

