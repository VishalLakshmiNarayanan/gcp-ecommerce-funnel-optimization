SELECT * FROM `usereventsanalytics.querydata.userevents` LIMIT 10

-- sales funnel

WITH funnel_stages as (
  SELECT
  COUNT (DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage_1_views,
  COUNT (DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage_2_cart,
  COUNT (DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
  COUNT (DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage_4_payment,
  COUNT (DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage_5_purchase
  FROM  `usereventsanalytics.querydata.userevents`

  WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
)

SELECT * FROM funnel_stages


-- conversion rates

WITH funnel_stages as (
  SELECT
  COUNT (DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage_1_views,
  COUNT (DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage_2_cart,
  COUNT (DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
  COUNT (DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage_4_payment,
  COUNT (DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage_5_purchase
  FROM  `usereventsanalytics.querydata.userevents`

  WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
)

SELECT
  stage_1_views,
  stage_2_cart,
  ROUND(stage_2_cart*100/stage_1_views) as view_to_cart_rate,

  stage_3_checkout,
  ROUND(stage_3_checkout*100/stage_2_cart) as cart_to_checkout_rate,

  stage_4_payment,
  ROUND(stage_4_payment*100/stage_3_checkout) as checkout_to_payment_rate,

  stage_5_purchase,
  ROUND(stage_5_purchase*100/stage_4_payment) as payment_to_purchase_rate,

  ROUND(stage_5_purchase*100/stage_1_views) as overall_conversion_rate,
FROM funnel_stages

--- funnel by source

WITH source_funnel as (
  SELECT
  traffic_source,
  
  COUNT (DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS views,
  COUNT (DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS carts,
  COUNT (DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchases
  FROM  `usereventsanalytics.querydata.userevents`

  WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
  group by traffic_source

  
)

SELECT

traffic_source,
views,
carts,
purchases,
ROUND(carts*100/views) as cart_conversion_rate,
ROUND(purchases*100/views) as purchase_conversion_rate,
ROUND(purchases*100/carts) as cart_to_purchase_rate,

FROM source_funnel
ORDER BY purchases desc

-- time to convertion analysis

WITH user_journey as (
  SELECT
  user_id,
  
  MIN (CASE WHEN event_type = 'page_view' THEN event_date END) AS view_time,
  MIN (CASE WHEN event_type = 'add_to_cart' THEN event_date END) AS cart_time,
  MIN (CASE WHEN event_type = 'purchase' THEN event_date END) AS purchase_time
  FROM  `usereventsanalytics.querydata.userevents`

  WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
  group by user_id
  HAVING MIN(CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL

)

SELECT

COUNT(*) as converted_users,
ROUND(AVG(TIMESTAMP_DIFF(cart_time,view_time,MINUTE)),2) AS avg_view_to_cart_minutes,
ROUND(AVG(TIMESTAMP_DIFF(purchase_time,cart_time,MINUTE)),2) AS avg_cart_to_purchase_minutes,
ROUND(AVG(TIMESTAMP_DIFF(purchase_time,view_time,MINUTE)),2) AS avg_total_minutes,
FROM user_journey

-- revenue funnel

WITH funnel_revenue as (
  SELECT
  COUNT (DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_visitors,
  COUNT (DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_buyers,
  SUM (CASE WHEN event_type = 'purchase' THEN amount END) AS total_revenue,
  COUNT (CASE WHEN event_type = 'purchase' THEN 1 END) AS total_orders,
  
  FROM  `usereventsanalytics.querydata.userevents`

  WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))

)
SELECT

total_visitors,
total_buyers,
ROUND(total_revenue,2),
total_orders,
ROUND(total_revenue/ total_orders,2) as avg_order_value,
ROUND(total_revenue/total_buyers,2) as revenue_per_buyer,
ROUND(total_revenue/total_visitors,2) as revenue_per_visitor

FROM funnel_revenue