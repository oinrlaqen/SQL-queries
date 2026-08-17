WITH filtered_block AS (
  SELECT
    element -> 'members' AS members_list,
    element -> 'values' AS values_list
  FROM import_sessions,
  LATERAL jsonb_array_elements(import_errors -> 'blockers') AS element
  WHERE id = '{{ log_id }}'
    AND element ->> 'error_type' = 'Two members with same SSN'
),
indexed_emails AS (
    (email_element ->> 'email') AS email,
    email_index
  FROM filtered_block,
  LATERAL jsonb_array_elements(members_list) WITH ORDINALITY AS m(email_element, email_index)
),
indexed_values AS (
  SELECT
    val_element AS value_entry,
    val_index
  FROM filtered_block,
  LATERAL jsonb_array_elements_text(values_list) WITH ORDINALITY AS v(val_element, val_index)
)

SELECT *,
  CASE
    WHEN conflicting_user_id = 'None' THEN 'no user id'
    ELSE 'https://crm.healthjoy.com/pha/crm' || conflicting_user_id
  END AS crm_link
FROM (
  SELECT
    e.email AS "email (from the file)"
    substring(v.value_entry from '\([^,]+,\s*([^)]+)\)') AS relationship,
    substring(v.value_entry from ':\s*(.*?)\.\s*Conflicting') AS conflicting_email,
    substring(v.value_entry from 'user_id=([^,]*)') AS conflicting_user_id,
    substring(v.value_entry from 'profile_id=([^,.]*)') AS conflicting_profile_id
  FROM indexed_emails e
  JOIN indexed_values v ON e.email_index = v.val_index
) AS i
ORDER BY (relationship = 'employee') DESC,
          relationship;
