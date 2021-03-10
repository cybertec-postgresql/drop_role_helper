CREATE FUNCTION drop_role_helper(regrole) RETURNS SETOF text
   LANGUAGE plpgsql SET search_path = pg_catalog,pg_temp STRICT AS
$$DECLARE
   t text;
BEGIN
   /* tables */
   FOR t IN
      SELECT format(
                'REVOKE ALL ON%s %s FROM %s;',
                CASE WHEN t.relkind = 'S'::"char" THEN ' SEQUENCE' ELSE '' END,
                t.oid::regclass,
                $1
             )
      FROM pg_class AS t
         CROSS JOIN LATERAL aclexplode(t.relacl) AS a
      WHERE a.grantee = $1
      GROUP BY t.oid, t.relkind
      ORDER BY t.oid::regclass::text
   LOOP
      RETURN NEXT t;
   END LOOP;

   /* columns */
   FOR t IN
      SELECT format(
                'REVOKE ALL (%s) ON %s FROM %s;',
                string_agg(quote_ident(c.attname), ', ' ORDER BY attnum),
                c.attrelid::regclass,
                $1
             )
      FROM pg_attribute AS c
         CROSS JOIN LATERAL aclexplode(c.attacl) AS a
      WHERE a.grantee = $1
      GROUP BY c.attrelid
      ORDER BY c.attrelid::regclass::text
   LOOP
      RETURN NEXT t;
   END LOOP;

   /* functions/procedures */
   FOR t IN
      SELECT format(
                'REVOKE ALL ON %s %s FROM %s;',
                CASE WHEN f.prokind = 'p'::"char" THEN 'PROCEDURE' ELSE 'FUNCTION' END,
                f.oid::regprocedure,
                $1
             )
      FROM pg_proc AS f
         CROSS JOIN LATERAL aclexplode(f.proacl) AS a
      WHERE a.grantee = $1
      GROUP BY f.oid, f.prokind
      ORDER BY f.oid::regprocedure::text
   LOOP
      RETURN NEXT t;
   END LOOP;

   /* schemas */
   FOR t IN
      SELECT format(
                'REVOKE ALL ON SCHEMA %s FROM %s;',
                s.oid::regnamespace,
                $1
             )
      FROM pg_namespace AS s
         CROSS JOIN LATERAL aclexplode(s.nspacl) AS a
      WHERE a.grantee = $1
      GROUP BY s.oid
      ORDER BY s.oid::regnamespace::text
   LOOP
      RETURN NEXT t;
   END LOOP;

   /* large objects */
   FOR t IN
      SELECT format(
                'REVOKE ALL ON LARGE OBJECT %s FROM %s;',
                l.oid,
                $1
             )
      FROM pg_largeobject_metadata AS l
         CROSS JOIN LATERAL aclexplode(l.lomacl) AS a
      WHERE a.grantee = $1
      GROUP BY l.oid
      ORDER BY l.oid
   LOOP
      RETURN NEXT t;
   END LOOP;

   /* types */
   FOR t IN
      SELECT format(
                'REVOKE ALL ON TYPE %s FROM %s;',
                t.oid::regtype,
                $1
             )
      FROM pg_type AS t
         CROSS JOIN LATERAL aclexplode(t.typacl) AS a
      WHERE a.grantee = $1
      GROUP BY t.oid
      ORDER BY t.oid::regtype::text
   LOOP
      RETURN NEXT t;
   END LOOP;

   /* languages */
   FOR t IN
      SELECT format(
                'REVOKE ALL ON LANGUAGE %I FROM %s;',
                l.lanname,
                $1
             )
      FROM pg_language AS l
         CROSS JOIN LATERAL aclexplode(l.lanacl) AS a
      WHERE a.grantee = $1
      GROUP BY l.lanname
      ORDER BY l.lanname
   LOOP
      RETURN NEXT t;
   END LOOP;

   /* databases */
   FOR t IN
      SELECT format(
                'REVOKE ALL ON DATABASE %I FROM %s;',
                d.datname,
                $1
             )
      FROM pg_database AS d
         CROSS JOIN LATERAL aclexplode(d.datacl) AS a
      WHERE a.grantee = $1
      GROUP BY d.datname
      ORDER BY d.datname
   LOOP
      RETURN NEXT t;
   END LOOP;

   /* tablespaces */
   FOR t IN
      SELECT format(
                'REVOKE ALL ON TABLESPACE %I FROM %s;',
                t.spcname,
                $1
             )
      FROM pg_tablespace AS t
         CROSS JOIN LATERAL aclexplode(t.spcacl) AS a
      WHERE a.grantee = $1
      GROUP BY t.spcname
      ORDER BY t.spcname
   LOOP
      RETURN NEXT t;
   END LOOP;

   /* foreign server */
   FOR t IN
      SELECT format(
                'REVOKE ALL ON FOREIGN SERVER %I FROM %s;',
                s.srvname,
                $1
             )
      FROM pg_foreign_server AS s
         CROSS JOIN LATERAL aclexplode(s.srvacl) AS a
      WHERE a.grantee = $1
      GROUP BY s.srvname
      ORDER BY s.srvname
   LOOP
      RETURN NEXT t;
   END LOOP;

   /* foreign data wrapper */
   FOR t IN
      SELECT format(
                'REVOKE ALL ON FOREIGN DATA WRAPPER %I FROM %s;',
                d.fdwname,
                $1
             )
      FROM pg_foreign_data_wrapper AS d
         CROSS JOIN LATERAL aclexplode(d.fdwacl) AS a
      WHERE a.grantee = $1
      GROUP BY d.fdwname
      ORDER BY d.fdwname
   LOOP
      RETURN NEXT t;
   END LOOP;

   /* default privileges */
   FOR t IN
      SELECT format(
                'ALTER DEFAULT PRIVILEGES FOR ROLE %s%s REVOKE ALL ON %s FROM %s;',
                r.defaclrole::regrole,
                CASE WHEN r.defaclnamespace <> 0
                     THEN format(' IN SCHEMA %s', r.defaclnamespace::regnamespace)
                     ELSE ''
                END,
                CASE r.defaclobjtype
                   WHEN 'r'::"char" THEN 'TABLES'
                   WHEN 'S'::"char" THEN 'SEQUENCES'
                   WHEN 'f'::"char" THEN 'FUNCTIONS'
                   WHEN 'T'::"char" THEN 'TYPES'
                   WHEN 'n'::"char" THEN 'SCHEMAS'
                END,
                $1
             )
      FROM pg_default_acl AS r
         CROSS JOIN LATERAL aclexplode(r.defaclacl) AS a
      WHERE a.grantee = $1
      GROUP BY r.defaclrole, r.defaclnamespace, r.defaclobjtype
      ORDER BY r.defaclrole::regrole::text,
               r.defaclnamespace::regnamespace::text,
               r.defaclobjtype
   LOOP
      RETURN NEXT t;
   END LOOP;
END;$$;
