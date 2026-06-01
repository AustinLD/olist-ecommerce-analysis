# Project 1: E-Commerce Performance & Customer Insights

## Problem Statement

A Brazilian e-commerce company (Olist) wants to understand what's driving revenue, where delivery performance is breaking down, and which customers are worth the most. The goal is to turn 100,000+ orders across 9 relational tables into a clear picture of business health, and surface the customer segments that matter most.

This project answers three core business questions:

1. How has revenue and order volume trended over time, and what's driving growth or decline?
2. Where are delivery failures concentrated, and is there a relationship between late deliveries and low review scores?
3. Which customers are high-value, and what does the RFM segmentation look like?

---

## Dataset

**Brazilian E-Commerce Public Dataset by Olist**

- Source: [kaggle.com/datasets/olistbr/brazilian-ecommerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- Size: ~100K orders, 2016-2018
- Tables: orders, order_items, order_payments, order_reviews, customers, geolocation, sellers, products, product_category_name_translation

Note in all write-ups: this is a real but anonymized public dataset. Findings are for skill demonstration, not operational conclusions.

---

## Tools & Stack

| Layer | Tool | Purpose |
| :---- | :---- | :---- |
| Data storage | MySQL (VS Code) | Store and query the 9 relational tables |
| SQL analysis | SQL (CTEs, window functions) | Revenue trends, RFM segmentation, delivery analysis |
| Python | Pandas, Matplotlib, Seaborn | Data cleaning, EDA, delivery/review correlation |
| Visualization | Power BI | Interactive dashboard for business stakeholders |
| AI component | OpenAI or Anthropic API | Auto-generated monthly narrative summary |
| Version control | GitHub | Code, SQL scripts, README, case study |

---

## Deliverables

### 1. SQL Analysis Script
A set of well-commented SQL queries demonstrating advanced techniques, including:

- Monthly revenue and order volume using window functions (LAG for MoM change, running totals with SUM() OVER)
- Average order value (AOV) and repeat-purchase rate via CTEs
- On-time delivery rate by seller state using CASE WHEN and GROUP BY
- RFM segmentation: Recency, Frequency, Monetary scoring using NTILE window functions
- Delivery delay analysis: days between estimated and actual delivery, joined to review scores

### 2. Python Notebook
A Jupyter notebook covering:

- Data loading and cleaning (handling nulls, parsing dates, merging tables)
- Exploratory data analysis with Seaborn/Matplotlib
- Correlation analysis: delivery delay vs. review score
- RFM score distribution visualization
- Output: clean, analysis-ready dataset exported for Power BI

### 3. Power BI Dashboard (4 pages)

- **Executive Overview:** Revenue, orders, AOV, on-time delivery rate as KPI cards with MoM trend lines
- **Geography:** Order volume and delivery performance by Brazilian state (filled map)
- **Product Categories:** Revenue and return rate by category with drill-through
- **Customer Segments:** RFM tier breakdown, high-value customer count, average spend per segment

### 4. AI Narrative Component
A Python script that calls an LLM API (OpenAI or Anthropic) to generate a short monthly business summary from the latest data, for example: "Revenue grew 12% MoM, led by Health & Beauty. Delivery delays are concentrated in the North region and correlate with a 0.4-point drop in average review score." Includes a human-review checkpoint note in the output.

### 5. Case Study Write-Up
A short document (500-800 words) structured as: Problem, Approach, Insights, Business Impact. Hosted on GitHub as the project README. Written for a hiring manager who has 90 seconds.

---

## Key Skills Demonstrated

- Advanced SQL: CTEs, window functions (LAG, NTILE, SUM OVER), multi-table joins
- Data modeling: star schema in Power BI with 9 source tables
- DAX: time intelligence measures (MoM, running total), KPI cards
- Python: data cleaning, EDA, correlation analysis
- Agentic AI: LLM API integration with a practical business use case
- Storytelling: business-framed write-up, not a methods report

---

## Milestones

| Week | Focus |
| :---- | :---- |
| Week 1 | Download dataset, load into SQLite, explore schema, write initial SQL queries |
| Week 2 | Complete SQL analysis scripts, Python cleaning and EDA notebook |
| Week 3 | Build Power BI data model and first two dashboard pages |
| Week 4 | Finish dashboard, build AI narrative script, write case study |

---

## GitHub Structure (planned)

```
olist-ecommerce-analysis/
├── data/               # Raw CSVs or SQLite DB (gitignored if large)
├── sql/                # All SQL scripts, named by analysis
├── notebooks/          # Jupyter notebooks for EDA and Python analysis
├── powerbi/            # .pbix file
├── ai_narrative/       # LLM narrative script
└── README.md           # Case study write-up
```

---

## Status

Active. Starting Week 1.
