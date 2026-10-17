/*
 * Dusklight for the PlayStation 5 - what runs before the game's main.
 *
 * Dusklight's main is its own (vendor/dusklight/src/dusk/main.cpp), so the
 * console's start-up is a constructor: standard error into klog and the
 * shell's splash dismissed, and the folder SDL derives its paths from.
 *
 * SPDX-License-Identifier: MIT
 */
#include <SDL3/SDL_stdinc.h>
#include <ps5platform/elevation.h>
#include <ps5platform/libc.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "platform.h"

__attribute__((constructor)) static void
ps5_startup(void)
{
   /* Hold the app's cwd across a possible root transition. Resolving it afterwards
    * with the SDK's getcwd retains the actual mounted files even if /app0 vanishes. */
   const int app_cwd = chdir("/app0");
   /* The pinned SDK already supplies Lapy's cooperative filesystem request.
    * Ask only when /data is not available, before any worker threads exist.
    * Failure is handled by a visible startup error; never use an unprotected ISO
    * or save directory as a silent fallback. No daemon is installed or started. */
   const int needs_data_access = access("/data", R_OK | W_OK) != 0;
   enum ps5_elevation_status status = PS5_ELEVATION_OK;
   if (needs_data_access) {
      status = ps5_elevation_request(PS5_ELEVATION_FILESYSTEM);
      if (status != PS5_ELEVATION_OK)
         setenv("DUSK_PS5_STORAGE_ERROR",
            "Persistent /data is unavailable. Start the Lapy owned-root daemon before Dusklight, then reopen the app. Original ISO and save files were retained.", 1);
   }
   /* Logging starts a klog reader thread. Keep it after the optional filesystem
    * request, which must run before any workers exist. */
   platform_init(PS5_TITLE_NAME);
   if (needs_data_access)
      say("persistent data access: %s", ps5_elevation_status_name(status));
   char app[4096], download[4096];
   if (app_cwd == 0 && ps5_getcwd(app, sizeof(app) - 1)) {
      const size_t length = strlen(app);
      strcpy(download, "/download0");
      if (length >= 5 && strcmp(app + length - 5, "/app0") == 0)
         snprintf(download, sizeof(download), "%.*s/download0", (int)(length - 5), app);
      if (length > 0 && app[length - 1] != '/') {
         app[length] = '/';
         app[length + 1] = '\0';
      }
      setenv("DUSK_PS5_APP_ROOT", app, 1);
      setenv("DUSK_PS5_DOWNLOAD_ROOT", download, 1);
      SDL_SetEnvironmentVariable(SDL_GetEnvironment(), "DUSK_PS5_APP_ROOT", app, true);
   } else {
      setenv("DUSK_PS5_STORAGE_ERROR", "Cannot resolve this title's mounted application folder. Original files were retained.", 1);
   }
   /* Defaults until game_main sets the protected override before loading data.
    * Set in SDL's own copy of the environment,
    * which is all SDL_getenv reads: the console's libc keeps what setenv sets
    * apart from the `environ` SDL copies. */
   SDL_SetEnvironmentVariable(SDL_GetEnvironment(), "XDG_DATA_HOME", "/app0/userdata", true);
   SDL_SetEnvironmentVariable(SDL_GetEnvironment(), "HOME", "/app0/userdata", true);
}
