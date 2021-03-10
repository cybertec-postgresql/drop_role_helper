EXTENSION = drop_role_helper
DATA = drop_role_helper--*.sql
DOCS = README.drop_role_helper
REGRESS = drop_role_helper

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
