DO $$ 
DECLARE 
    r RECORD;
BEGIN 
    FOR r IN 
        SELECT table_name, column_name
        FROM information_schema.columns
        WHERE data_type = 'text'
        AND table_schema = 'public'
        AND table_name NOT LIKE 'strapi_%'
    LOOP
        EXECUTE format(
            'ALTER TABLE %I ADD COLUMN %I_jsonb JSONB;',
            r.table_name, r.column_name
        );
        
        EXECUTE format(
            'UPDATE %I SET %I_jsonb = html_to_strapi_json(%I);',
            r.table_name, r.column_name, r.column_name
        );

        EXECUTE format(
            'ALTER TABLE %I DROP COLUMN %I;',
            r.table_name, r.column_name
        );

        EXECUTE format(
            'ALTER TABLE %I RENAME COLUMN %I_jsonb TO %I;',
            r.table_name, r.column_name, r.column_name
        );
    END LOOP;
END $$;
