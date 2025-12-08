-- CTE 1: Base session info
WITH session_info AS (
  SELECT s.date,
         s.ga_session_id,
         sp.country,
         sp.device,
         sp.continent,
         sp.channel,
         ab.test,
         ab.test_group
  FROM `DA.ab_test` ab
  JOIN `DA.session` s
    ON ab.ga_session_id = s.ga_session_id
  JOIN `DA.session_params` sp
    ON sp.ga_session_id = ab.ga_session_id
),

-- CTE 2: Sessions with orders
session_with_orders AS (
  SELECT session_info.date,
         session_info.country,
         session_info.device,
         session_info.continent,
         session_info.channel,
         session_info.test,
         session_info.test_group,
         COUNT(DISTINCT o.ga_session_id) AS session_with_orders
  FROM `DA.order` o
  JOIN session_info
    ON o.ga_session_id = session_info.ga_session_id
  GROUP BY 1, 2, 3, 4, 5, 6, 7
),

-- CTE 3: Events
events AS (
  SELECT session_info.date,
         session_info.country,
         session_info.device,
         session_info.continent,
         session_info.channel,
         session_info.test,
         session_info.test_group,
         ep.event_name,
         COUNT(ep.ga_session_id) AS event_cnt
  FROM `DA.event_params` ep
  JOIN session_info
    ON ep.ga_session_id = session_info.ga_session_id
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),

-- CTE 4: Total sessions
session AS (
  SELECT session_info.date,
         session_info.country,
         session_info.device,
         session_info.continent,
         session_info.channel,
         session_info.test,
         session_info.test_group,
         COUNT(DISTINCT session_info.ga_session_id) AS session_cnt
  FROM session_info
  GROUP BY 1, 2, 3, 4, 5, 6, 7
),

-- CTE 5: New accounts
account AS (
  SELECT session_info.date,
         session_info.country,
         session_info.device,
         session_info.continent,
         session_info.channel,
         session_info.test,
         session_info.test_group,
         COUNT(DISTINCT acs.ga_session_id) AS new_account_cnt
  FROM `DA.account_session` acs
  JOIN session_info
    ON acs.ga_session_id = session_info.ga_session_id
  GROUP BY 1, 2, 3, 4, 5, 6, 7
)

-- Final UNION of all metrics
SELECT session_with_orders.date,
       session_with_orders.country,
       session_with_orders.device,
       session_with_orders.continent,
       session_with_orders.channel,
       session_with_orders.test,
       session_with_orders.test_group,
       "session with orders" AS event_name,
       session_with_orders.session_with_orders AS value
FROM session_with_orders
UNION ALL
SELECT events.date,
       events.country,
       events.device,
       events.continent,
       events.channel,
       events.test,
       events.test_group,
       event_name,
       events.event_cnt AS value
FROM events
UNION ALL
SELECT session.date,
       session.country,
       session.device,
       session.continent,
       session.channel,
       session.test,
       session.test_group,
       "session" AS event_name,
       session.session_cnt AS value
FROM session
UNION ALL
SELECT account.date,
       account.country,
       account.device,
       account.continent,
       account.channel,
       account.test,
       account.test_group,
       "new account" AS event_name,
       account.new_account_cnt AS value
FROM account;
