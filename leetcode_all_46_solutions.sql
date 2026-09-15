-- =========================================
-- 1. Recyclable and Low Fat Products
-- =========================================

# Write your MySQL query statement below
SELECT
    product_id
FROM Products
WHERE low_fats = 'Y' AND recyclable = 'Y';

-- =========================================
-- 2. Find Customer Referee
-- =========================================

SELECT
    name
FROM Customer
WHERE referee_id != 2 OR referee_id IS NULL;

-- =========================================
-- 3. Department Top Three Salaries
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        d.name as depart,
        e.id,
        e.name,
        e.salary
    FROM Employee e
    JOIN Department d ON d.id = e.departmentId
),
step2 AS(
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY depart ORDER BY salary DESC) AS rnk
    FROM step1
),
step3 AS(
    SELECT
        *
    FROM step2
    WHERE rnk=1 OR rnk=2 OR rnk=3
)

SELECT
    depart AS Department,
    name AS Employee,
    salary AS Salary
FROM step3

-- =========================================
-- 4. Investments in 2016
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        *,
        DENSE_RANK() OVER(PARTITION BY tiv_2015 ORDER BY pid) AS rnk,
        COUNT(*) OVER(PARTITION BY lat, lon) AS cnt_location
    FROM Insurance  
),
step2 AS(
    SELECT
        *,
        LEAD(rnk) OVER(PARTITION BY tiv_2015 ORDER BY pid) AS nxt
    FROM step1
),
step3 AS(
    SELECT
        *,
        CASE
            WHEN rnk + 1 = nxt THEN 1
            WHEN nxt IS NULL AND rnk > 1 THEN 1
            ELSE 0
        END AS filter
    FROM step2
)

SELECT 
    ROUND(SUM(tiv_2016), 2) AS tiv_2016 
FROM step3
WHERE filter = 1
  AND cnt_location = 1;

-- =========================================
-- 5. Friend Requests II: Who Has the Most Friends
-- =========================================

# Write your MySQL query statement below
# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        accepter_id,
        requester_id,
        ROW_NUMBER() OVER(PARTITION BY accepter_id) AS cnt_a
    FROM RequestAccepted
),
step2 AS(
    SELECT
        *,
        MAX(cnt_a) OVER(PARTITION BY accepter_id) AS mx_a
    FROM step1
),
step3 AS(
    SELECT
        accepter_id AS a_id,
        mx_a AS a_num
    FROM step2
    WHERE mx_a=cnt_a
),
step4 AS(
    SELECT
        accepter_id,
        requester_id,
        ROW_NUMBER() OVER(PARTITION BY requester_id) AS cnt_r
    FROM RequestAccepted
),
step5 AS(
    SELECT
        *,
        MAX(cnt_r) OVER(PARTITION BY requester_id) AS mx_r
    FROM step4
),
step6 AS(
    SELECT
        requester_id AS r_id,
        mx_r AS r_num
    FROM step5
    WHERE mx_r=cnt_r
),
step7 AS(
    SELECT s3.a_id, s3.a_num, s6.r_id, s6.r_num
    FROM step3 s3
    LEFT JOIN step6 s6 ON s6.r_id=s3.a_id
    
    UNION
    
    SELECT s3.a_id, s3.a_num, s6.r_id, s6.r_num
    FROM step3 s3
    RIGHT JOIN step6 s6 ON s6.r_id=s3.a_id
),
step8 AS(
    SELECT
        COALESCE(a_id, r_id) AS final_id,
        (COALESCE(a_num, 0) + COALESCE(r_num,0)) AS sum
    FROM step7
)

SELECT
    final_id AS id,
    sum AS num
FROM step8
ORDER BY sum DESC
LIMIT 1;

-- =========================================
-- 6. Restaurant Growth
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT visited_on, SUM(amount) AS day_amount 
    FROM Customer 
    GROUP BY visited_on
    ORDER BY visited_on
),
step2 AS(
    SELECT
        visited_on,
        day_amount,
        SUM(day_amount) OVER(ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS sum_7_days
    FROM step1
),
step3 AS(
    SELECT
        *,
        AVG(day_amount) OVER(ORDER BY visited_on ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_7_days
    FROM step2
)

SELECT
    visited_on,
    sum_7_days AS amount,
    ROUND(avg_7_days, 2) AS average_amount
FROM step3
LIMIT 6, 18446744073709551615

-- =========================================
-- 7. Movie Rating
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        m.user_id,
        u.name,
        m.rating
    FROM MovieRating m
    JOIN Users u ON u.user_id=m.user_id
),
step2 AS(
    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY user_id) AS cnt
    FROM step1
),
step3 AS(
    SELECT
        *,
        MAX(cnt) OVER(PARTITION BY user_id) AS mx
    FROM step2
),
step4 AS(
    SELECT
        *
    FROM step3
    WHERE cnt=mx
    ORDER BY mx DESC, name ASC
    LIMIT 1  
),
step5 AS(
    SELECT
        m.movie_id,
        mo.title,
        m.rating
    FROM MovieRating m
    JOIN Movies mo ON mo.movie_id=m.movie_id
    WHERE m.created_at >= '2020-02-01' AND m.created_at <= '2020-02-29'
),
step6 AS(
    SELECT
        *,
        AVG(rating) OVER(PARTITION BY movie_id) AS avg_rate
    FROM step5
),
step7 AS(
    SELECT 
        DISTINCT title
    FROM step6
    ORDER BY avg_rate DESC, title ASC 
    LIMIT 1
)

SELECT name AS results FROM step4 
UNION ALL
SELECT title FROM step7

-- =========================================
-- 8. Exchange Seats
-- =========================================

# Write your MySQL query statement below
WITH step1 AS (
    SELECT
        *,
        LEAD(student) OVER(ORDER BY id) AS next,
        LAG(student) OVER(ORDER BY id) AS prev
    FROM Seat
),
step2 AS (
    SELECT
        MAX(id) AS max_id
    FROM step1
),
step3 AS (
    SELECT
        s1.id,
        s1.student,
        CASE
            WHEN s1.id=s2.max_id AND s1.id % 2 != 0 THEN s1.student
            WHEN s1.id%2!=0 THEN s1.next
            ELSE s1.prev
        END AS new_name
    FROM step1 s1
    CROSS JOIN step2 s2
    ORDER BY s1.id
)
SELECT id, new_name AS student FROM step3

-- =========================================
-- 9. Employees Whose Manager Left the Company
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        *
    FROM Employees
    WHERE manager_id IS NOT NULL AND salary<30000
),
step2 AS(
    SELECT
        employee_id
    FROM step1
    WHERE manager_id NOT IN (SELECT DISTINCT employee_id FROM Employees)
)

SELECT * FROM step2
ORDER BY employee_id

-- =========================================
-- 10. Count Salary Categories
-- =========================================

# Write your MySQL query statement below
-- WITH step1 AS(
--     SELECT
--         *
--     FROM Accounts
--     WHERE income < 20000
-- ),
-- step2 AS(
--     SELECT
--         *
--     FROM Accounts
--     WHERE income<=50000 AND income>=20000
-- ),
-- step3 AS(
--     SELECT
--         *
--     FROM Accounts
--     WHERE income > 50000
-- )
WITH AllCategories AS (
    SELECT 'Low Salary' AS category
    UNION ALL
    SELECT 'Average Salary'
    UNION ALL
    SELECT 'High Salary'
),
CategorizedAccounts AS (
    SELECT
        income,
        CASE 
            WHEN income < 20000 THEN 'Low Salary'
            WHEN income <= 50000 AND income >= 20000 THEN 'Average Salary'
            WHEN income > 50000 THEN 'High Salary'
            ELSE '0'
        END AS category
    FROM Accounts 
)

SELECT 
    c.category,
    COUNT(a.category) AS accounts_count
FROM AllCategories c
LEFT JOIN CategorizedAccounts a ON c.category = a.category
GROUP BY c.category;

-- =========================================
-- 11. Last Person to Fit in the Bus
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        *,
        MIN(weight) OVER(PARTITION BY turn ORDER BY weight) AS min_weight
    FROM Queue
    ORDER BY turn ASC, weight ASC
),
step2 AS(
    SELECT
        *
    FROM step1
    WHERE weight = min_weight
),
step3 AS(
    SELECT
        *,
        SUM(min_weight) OVER(ORDER BY turn) AS total_weight
    FROM step2
),
step4 AS(
    SELECT
        *
    FROM step3
    WHERE total_weight<=1000
)

SELECT
    person_name
FROM step4
ORDER BY total_weight DESC
LIMIT 1;

-- =========================================
-- 12. Product Price at a Given Date
-- =========================================

WITH step1 AS (
    SELECT
        product_id,
        new_price,
        ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY change_date DESC) AS rn
    FROM Products
    WHERE change_date <= '2019-08-16'
),
exclude AS (
    SELECT DISTINCT product_id 
    FROM Products
    WHERE product_id NOT IN (SELECT product_id FROM step1)
)

SELECT 
    product_id, 
    new_price AS price 
FROM step1 
WHERE rn = 1

UNION ALL

SELECT 
    product_id, 
    10 AS price 
FROM exclude;

-- =========================================
-- 13. Consecutive Numbers
-- =========================================

# Write your MySQL query statement below
WITH step1 AS (
    SELECT
        id,
        num,
        LAG(num) OVER(ORDER BY id) AS prev_num,
        LEAD(num) OVER(ORDER BY id) AS next_num
    FROM Logs
),
step2 AS (
    SELECT
        id,
        num,
        prev_num,
        next_num,
        ROW_NUMBER() OVER(ORDER BY id) AS cnt_prev,
        ROW_NUMBER() OVER(ORDER BY id) AS cnt_next
    FROM step1
)

SELECT DISTINCT num AS ConsecutiveNums 
FROM step2 
WHERE num = prev_num AND num = next_num AND cnt_prev=cnt_next

-- =========================================
-- 14. Triangle Judgement
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        *,
        CASE WHEN x<y+z THEN 1 ELSE 0 END AS A,
        CASE WHEN y<x+z THEN 1 ELSE 0 END AS B,
        CASE WHEN z<y+x THEN 1 ELSE 0 END AS C
    FROM Triangle
),
step2 AS(
    SELECT
        *,
        (A+B+C) AS filter
    FROM step1
)

SELECT
    x,
    y,
    z,
    CASE WHEN filter=3 THEN 'Yes' ELSE 'No' END AS triangle
FROM step2

-- =========================================
-- 15. Primary Department for Each Employee
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY employee_id ORDER BY department_id) AS cnt
    FROM Employee
),

step2 AS(
    SELECT
        *,
        MAX(cnt) OVER(PARTITION BY employee_id) AS mx
    FROM step1
),

step3 AS(
    SELECT
        *
    FROM step2
    WHERE mx = 1
),

step4 AS(
    SELECT
        *
    FROM step2
    WHERE mx > 1 AND primary_flag = 'Y' 
)

SELECT employee_id, department_id FROM step3
UNION ALL
SELECT employee_id, department_id FROM step4;

-- =========================================
-- 16. The Number of Employees Which Report to Each Employee
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        employee_id,
        name
    FROM Employees
),

step2 AS(
    SELECT
        employee_id,
        name,
        reports_to,
        age,
        AVG(age) OVER(PARTITION BY reports_to) AS avg_year,
        ROW_NUMBER() OVER(PARTITION BY reports_to ORDER BY employee_id) AS cnt
    FROM Employees
    WHERE reports_to IS NOT NULL
),
step3 AS(
    SELECT
        *,
        MAX(cnt) OVER(PARTITION BY reports_to) AS mx
    FROM step2
)

SELECT DISTINCT
    st1.employee_id,
    st1.name,
    st3.mx AS reports_count,
    ROUND(st3.avg_year) AS average_age
FROM step1 st1
JOIN step3 st3 ON st1.employee_id = st3.reports_to
ORDER BY st1.employee_id;

-- =========================================
-- 17. Customers Who Bought All Products
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT DISTINCT customer_id, product_key
    FROM Customer
),
step2 AS(
    SELECT 
        customer_id,
        product_key,
        COUNT(*) OVER(PARTITION BY customer_id) AS unique_products_count
    FROM step1
)

SELECT 
    DISTINCT customer_id
FROM step2
WHERE unique_products_count=(SELECT COUNT(*) FROM Product)

-- =========================================
-- 18. Biggest Single Number
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        num,
        ROW_NUMBER() OVER(PARTITION BY num) AS cnt
    FROM MyNumbers
),
step2 AS(
    SELECT
        *,
        MAX(cnt) OVER(PARTITION BY num) AS mx
    FROM step1
)

SELECT (
    SELECT num
    FROM step2
    WHERE mx = 1
    ORDER BY num DESC
    LIMIT 1
) AS num;

-- =========================================
-- 19. Find Followers Count
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY follower_id) AS cnt
    FROM Followers
),

step2 AS(
    SELECT
        *,
        MAX(cnt) OVER(PARTITION BY user_id) AS mx
    FROM step1
)

SELECT
    user_id,
    cnt AS followers_count
FROM step2
WHERE cnt=mx

-- =========================================
-- 20. Classes With at Least 5 Students
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY class) AS cnt
    FROM Courses
),
step2 AS(
    SELECT
        *,
        MAX(cnt) OVER(PARTITION BY class) AS mx
    FROM step1
)

SELECT
    class
FROM step2
WHERE cnt=mx AND mx>=5

-- =========================================
-- 21. Product Sales Analysis III
-- =========================================

# Write your MySQL query statement below
WITH step1 AS (
    SELECT
        *,
        LAG(year) OVER(PARTITION BY product_id ORDER BY year) AS prev_year
    FROM Sales
),

step2 AS (
    SELECT
        *
    FROM step1
    WHERE prev_year IS NULL
)

SELECT
    st1.product_id,
    st1.year AS first_year,
    st1.quantity,
    st1.price
FROM step1 st1
JOIN step2 st2 ON st2.product_id = st1.product_id AND st2.year = st1.year;




-- SELECT 
--     product_id,
--     year,
--     count,
--     CASE 
--         WHEN year - prev_year = 0 THEN 1
--         ELSE 0 
--     END AS year_status
-- FROM STEP2

-- =========================================
-- 22. User Activity for the Past 30 Days I
-- =========================================

# Write your MySQL query statement below
WITH step1 AS (
    SELECT 
        user_id,
        activity_date,
        CASE 
            WHEN LAG(user_id) OVER(PARTITION BY activity_date ORDER BY user_id) != user_id
                 OR LAG(user_id) OVER(PARTITION BY activity_date ORDER BY user_id) IS NULL THEN 1 
            ELSE 0 
        END AS is_unique
    FROM Activity
    WHERE activity_date BETWEEN '2019-06-28' AND '2019-07-27'
),
step2 AS(
    SELECT
        activity_date,
        SUM(is_unique) OVER(PARTITION BY activity_date) AS total_uni
    FROM step1
),
maximum AS(
    SELECT
        *,
        MAX(total_uni) OVER(PARTITION BY activity_date) as tot_max
    FROM step2
)

SELECT DISTINCT
    activity_date AS day,
    total_uni AS active_users
FROM maximum
WHERE total_uni = tot_max


--     activity_date AS day,
--     cnt
-- FROM step2
-- WHERE cnt=total_cnt

-- =========================================
-- 23. Number of Unique Subjects Taught by Each Teacher
-- =========================================

# Write your MySQL query statement below
WITH step1 AS (
    SELECT
        *,
        CASE 
            WHEN LAG(subject_id) OVER(PARTITION BY teacher_id ORDER BY subject_id) != subject_id 
                 OR LAG(subject_id) OVER(PARTITION BY teacher_id ORDER BY subject_id) IS NULL THEN 1 
            ELSE 0 
        END AS is_unique
    FROM Teacher
)
SELECT 
    teacher_id,
    SUM(is_unique) AS cnt
FROM step1
GROUP BY teacher_id;


-- step2 AS(
--     SELECT
--         *,
--         MAX(count) OVER(PARTITION BY teacher_id) as max_subj
--     FROM step1
-- )

-- SELECT 
--     teacher_id,
--     max_subj as cnt
-- FROM step2 
-- WHERE count=max_subj

-- =========================================
-- 24. Game Play Analysis IV
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY player_id ORDER BY event_date) as day_num_cnt,
        DATEDIFF(event_date, LAG(event_date) OVER(PARTITION BY player_id ORDER BY event_date)) as day_1_left
    FROM Activity
)



SELECT
    ROUND((SUM(CASE WHEN day_1_left=1 and day_num_cnt=2 THEN 1 ELSE 0 END)/(SELECT COUNT(DISTINCT player_id) FROM Activity)),2) AS fraction  
FROM step1

-- =========================================
-- 25. Immediate Food Delivery II
-- =========================================

# Write your MySQL query statement below
with classification_order AS(
    SELECT
        customer_id,
        order_date,
        customer_pref_delivery_date,
        CASE WHEN order_date=customer_pref_delivery_date THEN 'immediate' ELSE 'scheduled' END AS prefer,
        CASE WHEN ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) = 1 THEN 1 ELSE 0 END AS type_order
    FROM Delivery
    ORDER BY customer_id, order_date
),

final AS(
    select
        SUM(CASE WHEN prefer='immediate' AND type_order='1' THEN 1 ELSE 0 END) as total_sum
    FROM classification_order

)

SELECT
    ROUND(((total_sum/(SELECT COUNT(DISTINCT customer_id) FROM Delivery))*100), 2) AS immediate_percentage
FROM final

-- =========================================
-- 26. Monthly Transactions I
-- =========================================

# Write your MySQL query statement below
SELECT
    DATE_FORMAT(trans_date, '%Y-%m') AS month,
    country,
    COUNT(id) AS trans_count,
    SUM(CASE WHEN state='approved' THEN 1 ELSE 0 END) AS approved_count,
    SUM(amount) AS trans_total_amount,
    SUM(CASE WHEN state='approved' THEN amount ELSE 0 END) AS approved_total_amount
FROM Transactions
GROUP BY month, country

-- =========================================
-- 27. Queries Quality and Percentage
-- =========================================

# Write your MySQL query statement below
SELECT 
    query_name,
    ROUND(AVG(rating / position), 2) AS quality,
    ROUND(AVG(CASE WHEN rating < 3 THEN 1 ELSE 0 END) * 100, 2) AS poor_query_percentage
FROM Queries
WHERE query_name IS NOT NULL
GROUP BY query_name;

-- =========================================
-- 28. Percentage of Users Attended a Contest
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        contest_id,
        COUNT(user_id) as total_people
    FROM Register
    GROUP BY contest_id
),

step2 AS(
    SELECT
        contest_id,
        ROUND((total_people / (SELECT COUNT(*) FROM Users)) * 100, 2) AS percentage
    FROM step1
)

SELECT * FROM step2
ORDER BY percentage DESC, contest_id ASC

-- =========================================
-- 29. Project Employees I
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        p.project_id,
        p.employee_id,
        e.experience_years
    FROM Project p
    LEFT JOIN Employee e ON e.employee_id=p.employee_id
),

step2 AS(
    SELECT
        project_id,
        SUM(experience_years) as total_years,
        COUNT(employee_id) as total_employee
    FROM step1
    GROUP BY project_id
)


SELECT
    project_id,
    ROUND((total_years/total_employee),2) as average_years
FROM step2

-- =========================================
-- 30. Average Selling Price
-- =========================================

WITH step1 AS(
    SELECT
        product_id,
        units,
        SUM(units) as total_count
    FROM UnitsSold
    GROUP BY product_id
),

step2 AS(
    SELECT
        p.product_id,
        IFNULL(SUM(u.units*p.price), 0) as total_money
    FROM Prices p
    LEFT JOIN UnitsSold u ON u.product_id = p.product_id 
                  AND u.purchase_date BETWEEN p.start_date AND p.end_date
    GROUP BY p.product_id
),

step3 AS(
    SELECT
        s2.product_id,
        s2.total_money,
        CASE WHEN s2.total_money!=0 THEN s2.total_money ELSE 0 END as all_money,
        s1.total_count
    FROM step2 s2
    LEFT JOIN step1 s1 ON s1.product_id = s2.product_id
    GROUP BY product_id
)

SELECT
    product_id,
    CASE WHEN all_money IS NOT NULL AND all_money!=0 AND total_count IS NOT NULL AND total_count!=0 THEN ROUND((all_money/total_count), 2) ELSE 0 END AS average_price
FROM step3

-- =========================================
-- 31. Not Boring Movies
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        CASE WHEN id%2!=0 THEN id ELSE 0 END as id,
        movie,
        CASE WHEN description='boring' THEN NULL ELSE description END as description,
        rating
    FROM Cinema
)

SELECT *
FROM step1
WHERE id!=0 AND description IS NOT NULL
ORDER BY rating DESC

-- =========================================
-- 32. Confirmation Rate
-- =========================================

# Write your MySQL query statement below
WITH step1 AS(
    SELECT
        s.user_id,
        s.time_stamp,
        SUM(CASE WHEN c.action = 'confirmed' THEN 1 ELSE 0 END) AS confirmed_count,
        SUM(CASE WHEN c.action IS NOT NULL THEN 1 ELSE 0 END) as all_count
    FROM Signups s
    LEFT JOIN Confirmations c ON c.user_id=s.user_id
    GROUP BY s.user_id, s.time_stamp
)

SELECT
    user_id,
    IFNULL(ROUND((confirmed_count/all_count),2), 0) as confirmation_rate
FROM step1

-- =========================================
-- 33. Managers with at Least 5 Direct Reports
-- =========================================

# Write your MySQL query statement below
WITH managers AS (
    SELECT managerId
    FROM Employee
    GROUP BY managerId
    HAVING COUNT(*) >= 5
)

SELECT name
FROM Employee
WHERE id IN (SELECT managerId FROM managers);

-- =========================================
-- 34. Students and Examinations
-- =========================================

WITH full as(
    SELECT
        st.student_id,
        st.student_name,
        sub.subject_name
    FROM Students st
    CROSS JOIN Subjects sub
)
        
SELECT
    f.student_id,
    f.student_name,
    f.subject_name,
    COUNT(ex.student_id) AS attended_exams
FROM full f
LEFT JOIN Examinations ex ON ex.student_id = f.student_id AND ex.subject_name = f.subject_name
GROUP BY f.student_id, f.student_name, f.subject_name
ORDER BY f.student_id, f.subject_name

-- =========================================
-- 35. Employee Bonus
-- =========================================

# Write your MySQL query statement below
SELECT
    e.name,
    b.bonus
FROM Employee e
LEFT JOIN Bonus b ON e.empId = b.empId
WHERE b.bonus<1000 OR b.bonus IS NULL;

-- =========================================
-- 36. Average Time of Process per Machine
-- =========================================

SELECT 
    a1.machine_id,
    ROUND(AVG(a2.timestamp - a1.timestamp), 3) as processing_time
FROM Activity a1
JOIN Activity a2 
    ON a1.machine_id = a2.machine_id 
    AND a1.process_id = a2.process_id
WHERE a1.activity_type = 'start' 
  AND a2.activity_type = 'end'
GROUP BY a1.machine_id;

-- =========================================
-- 37. Rising Temperature
-- =========================================

# Write your MySQL query statement below
WITH prepared_weather AS (
    SELECT
        id,
        recordDate,
        temperature,
        LAG(temperature) OVER(ORDER BY recordDate) as prev_temp,
        LAG(recordDate) OVER(ORDER BY recordDate) as prev_date
    FROM Weather
)


-- SELECT * FROM prepared_weather
SELECT id 
FROM prepared_weather
WHERE temperature > prev_temp 
  AND DATEDIFF(recordDate, prev_date) = 1;

-- =========================================
-- 38. Customer Who Visited but Did Not Make Any Transactions
-- =========================================

# Write your MySQL query statement below
SELECT
    v.customer_id,
    COUNT(*) AS count_no_trans
FROM Visits v
LEFT JOIN Transactions t ON t.visit_id=v.visit_id
WHERE t.transaction_id IS NULL
GROUP BY v.customer_id;

-- =========================================
-- 39. Product Sales Analysis I
-- =========================================

# Write your MySQL query statement below
SELECT
    p.product_name,
    s.year,
    s.price
FROM Product p
INNER JOIN Sales s ON s.product_id=p.product_id;

-- =========================================
-- 40. Replace Employee ID With The Unique Identifier
-- =========================================

# Write your MySQL query statement below
SELECT
    eu.unique_id,
    e.name
FROM Employees e
LEFT JOIN EmployeeUNI eu ON e.id = eu.id;

-- =========================================
-- 41. Invalid Tweets
-- =========================================

# Write your MySQL query statement below
SELECT
    tweet_id
FROM Tweets
WHERE CHAR_LENGTH(REPLACE(content, ' ', ''))>15;

-- =========================================
-- 42. Article Views I
-- =========================================

# Write your MySQL query statement below
SELECT
    DISTINCT author_id as id
FROM Views
WHERE viewer_id = author_id
ORDER BY author_id;

-- =========================================
-- 43. Big Countries
-- =========================================

# Write your MySQL query statement below
SELECT
    name,
    population,
    area
FROM World
WHERE area>=3000000 OR population>=25000000;

-- =========================================
-- 44. Longest Common Prefix
-- =========================================

class Solution:
    def longestCommonPrefix(self, strs: list[str]) -> str:
        if not strs:
            return ""

        first_str = strs[0]

        for i in range(len(first_str)):
            char = first_str[i]
            for other_str in strs[1:]:
                if i == len(other_str) or other_str[i] != char:
                    return first_str[:i]

        return first_str

-- =========================================
-- 45. Roman to Integer
-- =========================================

class Solution:
    def romanToInt(self, s: str) -> int:
        roman_map = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}
        total = 0
        
        for i in range(len(s) - 1):
            if roman_map[s[i]] < roman_map[s[i+1]]:
                total -= roman_map[s[i]]
            else:
                total += roman_map[s[i]]
        
        total += roman_map[s[-1]]
        return total

-- =========================================
-- 46. Two Sum
-- =========================================

class Solution:
    def twoSum(self, nums: list[int], target: int) -> list[int]:
        was = {}
        for index, value in enumerate(nums):
            val = target - value
            if val in was:
                return [was[val], index]
            was[value] = index
        return []

