#include <sqlite3ext.h>
#include <string.h>
/* Apple's headers disable the extension macros, so use the supplied API directly. */
static const sqlite3_api_routines *sqlite_api;

static void answer(sqlite3_context *context, int argc, sqlite3_value **argv) {
  sqlite_api->result_int(context, 42);
}

static int install(sqlite3 *db, char **error, const char *name) {
  char *message = 0;
  int code = sqlite_api->exec(db, "SELECT load_extension('sqlite3-must-not-load')",
                             0, 0, &message);
  int denied = code == SQLITE_ERROR && message &&
               strcmp(message, "not authorized") == 0;
  sqlite_api->free(message);
  if (!denied) {
    *error = sqlite_api->mprintf("SQL extension loading was enabled during initialization");
    return SQLITE_ERROR;
  }
  return sqlite_api->create_function(db, name, 0, SQLITE_UTF8, 0, answer, 0, 0);
}

int sqlite3_extension_init(sqlite3 *db, char **error,
                           const sqlite3_api_routines *api) {
  sqlite_api = api;
  return install(db, error, "test_extension");
}

int sqlite3_alternative_init(sqlite3 *db, char **error,
                             const sqlite3_api_routines *api) {
  sqlite_api = api;
  return install(db, error, "test_alternative_extension");
}

int sqlite3_failure_init(sqlite3 *db, char **error,
                         const sqlite3_api_routines *api) {
  sqlite_api = api;
  *error = sqlite_api->mprintf("fixture initialization failed");
  return SQLITE_ERROR;
}
