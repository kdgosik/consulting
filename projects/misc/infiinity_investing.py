import pandas as pd
import yfinance as yf
import seaborn as sns
import matplotlib.pyplot as plt

dividend_rate = 0.04 # yearly rate
growth_rate = 0.1 # yearly rate
covered_call_rate = 0.002 # per month rate
loan_rate = 0.05 # yearly rate
borrow_amount_rate = 0.01 # per month rate

principal = 3_000
borrow_amount = principal * borrow_amount_rate
loan_amount = 0


add_loan_to_principal = True

def calculate_infinite_value(dividend_rate, growth_rate):
    if growth_rate >= dividend_rate:
        raise ValueError("Growth rate must be less than the dividend rate for the formula to be valid.")
    return dividend_rate / (dividend_rate - growth_rate)


## Next Steps:
## if principal is under 3_000 do not create covered call revenue
    if principal < 3_000:
        coverd_call_revenue = 0
    else:
        coverd_call_revenue = principal * covered_call_rate 
## run retrospective examples with SCHD and SPY
## if loan_amount < 0, add covered call revenue to principal instead of subtracting it from loan amount
l = []
for month in range(1, 240):
    coverd_call_revenue = principal * covered_call_rate
    dividend_revenue = principal * dividend_rate / 12
    principal += dividend_revenue
    loan_amount *= (1 + loan_rate / 12)
    loan_amount += borrow_amount - coverd_call_revenue
    loan_to_value = loan_amount / principal

    if add_loan_to_principal:
        principal += borrow_amount

    l.append({
        "month": month,
        "coverd_call_revenue": coverd_call_revenue,
        "dividend_revenue": dividend_revenue,
        "principal": principal,
        "loan_amount": loan_amount,
        "loan_to_value": loan_to_value
        })
    principal *= (1 + growth_rate / 12)

df = pd.DataFrame(l)

df_formatted = df.style.format({
    "coverd_call_revenue": "${:,.2f}",
    "dividend_revenue": "${:,.2f}",
    "principal": "${:,.2f}",
    "loan_amount": "${:,.2f}",
    "loan_to_value": "{:.2%}"
})


# Read SPY historical data from Yahoo Finance
spy = yf.download("SPY", start="2020-01-01", end="2026-01-01", progress=False, actions=True)
spy = spy.reset_index()
print(spy.head())

# Read SCHD historical data from Yahoo Finance
schd = yf.download("SCHD", start="2020-01-01", end="2026-01-01", progress=False, actions=True)
schd = schd.reset_index()
print(schd.head())