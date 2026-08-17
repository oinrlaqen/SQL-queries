WITH r AS

  (SELECT date, 
        import_file_source,
        uploaded_by,
        alias,
        error_message,
        tpa_channel,
        tpa_name,
        automation_status,
        group_lives_in
   FROM query_5323 AS v1

   UNION ALL 

   SELECT date, 
        import_file_source,
        uploaded_by,
        alias_v2,
        error_message,
        tpa_channel,
        tpa_name,
        automation_status,
        group_lives_in
   FROM query_5379 AS v2)

SELECT strftime('%d/%m/%Y', i.date) AS "date",
       i.import_file_source AS "sftp/een",
       i.uploaded_by,
       i.alias,
       i.error_message,
        CASE
            WHEN i.tpa_channel = 0 THEN 'no'
            WHEN i.tpa_channel = 1 THEN 'yes'
        END AS "tpa_channel",
       i.tpa_name,
       i.automation_status,
       i.group_lives_in
FROM

  (SELECT *,
          row_number() over (partition by alias order by date desc) AS rn
   FROM r
   WHERE date between ('{{Start Date}}') and ('{{End Date}}')) AS i

WHERE rn = 1
    AND i.automation_status LIKE '%automated%' COLLATE NOCASE
