/*****************************************************************************
 * License : All rights reserved for TES Electronic Solutions GmbH
 *           See included /docs/license.txt for details
 * Project : D/AVE NX
 * Purpose : Make build-time svnversion information available
 *           NOTE: THIS FILE IS AUTOGENERATED BY SVNVER SCRIPT
 ****************************************************************************/

#define SVNVERSION "$SVNVERSION$"
#define SVNDATE    "$SVNDATE$"

const char g_egl_svnversion_string[] = SVNVERSION;
const char g_egl_svndate_string[]    = SVNDATE;
const char g_egl_svnver_fileid[]     = "@@SVN:" SVNVERSION " egl";

const char *get_egl_svnver_fileid(void) { return g_egl_svnver_fileid; }

