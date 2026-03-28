# E-Commerce Sales & Customer Analytics

## Overview
This project analyzes e-commerce transactional data to understand how delivery performance, pricing, and seller behavior impact customer satisfaction and revenue. The focus is on deriving actionable business insights rather than just reporting metrics.

---

## Tools & Workflow
- **SQL** → Data cleaning, joining multiple tables, feature engineering  
- **Python** → Exploratory data analysis, visualization, and modeling  
- **Power BI** → Dashboarding and reporting *(in progress)*  

---

## Data Scope
The dataset consists of customers, orders, order items, payments, and reviews.  
These were integrated using SQL into a unified analytical table at the order-item level, enabling both customer-level and seller-level analysis.

- Combined multiple datasets into a single master table  
- Performed analysis at both order-level and customer-level granularity  
- Created an aggregated dataset for customer segmentation  

---

## Key Insights
- **Delivery delays reduce customer satisfaction**  
  Higher delivery delays are associated with lower review scores.

- **Revenue ≠ Customer satisfaction**  
  Some high-revenue cities show lower average ratings, indicating potential risks.

- **Mid-range pricing performs more consistently**  
  Extreme price segments show higher variability in customer reviews.

- **Seller performance is uneven**  
  A small group of sellers contributes disproportionately to delays.

- **Repeat customers are more stable**  
  Returning customers show more consistent satisfaction levels.

- **Churn is linked to delivery issues**  
  One-time customers often experience higher delays.

- **Shipping cost impacts behavior**  
  Freight charges influence both revenue patterns and customer perception.

- **Customer segments show clear patterns**  
  Clustering identifies groups like high-value loyal users and low-engagement users.

---

## Machine Learning
Customer segmentation using **KMeans clustering** based on:
- total_orders  
- total_revenue  
- avg_review  
- avg_delay  

---

## Status
- SQL: Completed  
- Python: Completed  
- Power BI: In Progress  

---

## Outcome
This project demonstrates an end-to-end data analytics workflow:
- Data preparation using SQL  
- Analysis and modeling using Python  
- Business-focused insights for decision-making  

---

## Next Steps
- Build interactive Power BI dashboard  
- Add business recommendations  
- Enhance segmentation and explore predictive models  
