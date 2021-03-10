This extension makes it easy to `DROP ROLE` in PostgreSQL.

It provides a function that helps you to revoke all privileges of a role in
a database.

Example
-------

You want to get rid of user `dummy` in the database.

If you want to keep the objects owned by the role, change their ownership to
a different role:

    REASSIGN OWNED BY dummy TO otheruser;

Then drop everything still owned by the role.  This is required even if you
ran `REASSIGN OWNED`, as some objects (for example user mappings) are not
affected.

    DROP OWNED BY dummy;

Then use the extension to get rid of all the permissions.  When using `psql`,
you can use the convenient `\gexec` to execute the function results as an
SQL script:

    CREATE EXTENSION drop_role_helper SCHEMA public;
    SELECT * FROM public.drop_role_helper('dummy') \gexec

Repeat the above statements in all databases in the PostgreSQL cluster.
Then you can drop the role:

    DROP ROLE dummy;

Installation
------------

To install the software, make sure that the correct `pg_config` is on the
`PATH`, change into the directory with the software and run

    sudo make install

Then install the extension in the databases where you need it:

    CREATE EXTENSION drop_role_helper;

If you don't have permission to install software on the database server,
you can simply run the SQL script that creates the function.  In that case
you don't need to call `CREATE EXTENSION`.

Usage
-----

The extension creates a single table function `drop_role_helper` that takes
a role name as argument and returns a table of SQL statements.

You need no special permissions to run the function, but to execute the
SQL statements returned by the function, you need to be a superuser or the
owner of all the affected objects.  If the role to be dropped has default
privileges, you must also be a member of the role for which the default
privileges are defined.

Support
-------

Please report problems by creating a [Github issue][1].  
Commercial support is available from [Cybertec][2].


  [1]: https://github.com/cybertec-postgresql/drop_role_helper/issues
  [2]: https://www.cybertec-postgresql.com/
