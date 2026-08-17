-- Query to filter people by they deductions amount (money spent on healthcare)
-- Based on CTE ("with" clause) + window function "row_number()"

WITH p AS
  
  (SELECT i.*,
     ROW_NUMBER() OVER (PARTITION BY first_name, last_name, dob ORDER BY last_update DESC)
   FROM
     
     (SELECT replace(concat(fs.id), ',', '') AS rec_id,
            DATE_TRUNC('day', fs.created) AS last_update,
            fs.status,
            fs.financial_payload ->> 'first_name' AS first_name,
            fs.financial_payload ->> 'last_name' AS last_name,
            to_char((fs.financial_payload ->> 'birthday')::date, 'MM/DD/YYYY') AS dob,
            mp.email,
            fs.financial_payload ->> 'in_network_deductible_amount_individual' AS in_network_individual,
            fs.financial_payload ->> 'in_network_deductible_amount_family' AS in_network_family,
            fs.financial_payload ->> 'in_network_out_of_pocket_amount_individual' AS in_network_oop_individual,
            fs.financial_payload ->> 'in_network_out_of_pocket_amount_family' AS in_network_oop_family,
            fs.financial_payload ->> 'out_of_network_deductible_amount_individual' AS out_of_network_individual,
            fs.financial_payload ->> 'out_of_network_deductible_amount_family' AS out_of_network_family,
            fs.financial_payload ->> 'out_of_network_out_of_pocket_amount_individual' AS out_of_network_oop_individual,
            fs.financial_payload ->> 'out_of_network_out_of_pocket_amount_family' AS out_of_network_oop_amount_family
      FROM financial_sync_records AS fs
      JOIN member_profiles AS mp ON fs.member_profile_id = mp.id
      JOIN financial_profiles AS fp ON fp.member_profile_id = mp.id
      WHERE company_alias = '{{alias}}') AS i)

SELECT rec_id,
     to_char(last_update, 'mm/dd/yy') AS last_update,
     status,
     first_name,
     last_name,
     dob,
     email,
     in_network_individual,
     in_network_family,
     in_network_oop_individual,
     in_network_oop_family,
     out_of_network_individual,
     out_of_network_family,
     out_of_network_oop_individual,
     out_of_network_oop_amount_family
FROM p
WHERE status = 'FINISHED'
    AND row_number = 1
    AND last_update = (SELECT MAX(last_update) FROM p)
