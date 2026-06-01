# Olist E-Commerce Performance & Customer Insights

## Overview

This project analyzes 100,000+ orders from Olist, a Brazilian e-commerce marketplace, to answer three core business questions:

1. How has revenue and order volume trended over time, and what's driving changes?
2. Where are delivery failures concentrated, and how do they affect customer satisfaction?
3. Which customers are the most valuable, and what does RFM segmentation reveal?

**Note:** This is a real but anonymized public dataset. Findings are for portfolio and skill demonstration purposes.

---

## Tools & Stack

| Layer | Tool |
| :---- | :---- |
| Database | MySQL |
| SQL Analysis | Advanced SQL (CTEs, window functions) |
| Python | Pandas, Matplotlib, Seaborn |
| Dashboard | Power BI |
| AI Component | LLM API (narrative generation) |
| Version Control | Git, GitHub |

---

## Dataset

**Brazilian E-Commerce Public Dataset by Olist**
Source: [kaggle.com/datasets/olistbr/brazilian-ecommerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

9 relational tables: orders, order items, payments, reviews, customers, geolocation, sellers, products, and category translations.

---

## Repository Structure

```
olist-ecommerce-analysis/
├── sql/                # SQL scripts for analysis
├── notebooks/          # Jupyter notebooks for EDA and Python analysis
├── powerbi/            # Power BI .pbix file
├── ai_narrative/       # LLM narrative generation script
└── README.md           # This file
```

---

## Key Findings

*To be updated as the project progresses.*

---

## How to Run

1. Download the dataset from Kaggle (link above) and place CSVs in a local `data/` folder.
2. Run `sql/00_setup_database.sql` in MySQL to create the database and load all tables.
3. Open the Jupyter notebooks in `notebooks/` for Python analysis.
4. Open `powerbi/olist_dashboard.pbix` in Power BI Desktop.

---

## Case Study

*Full write-up coming at project completion: Problem, Approach, Insights, Business Impact.*
