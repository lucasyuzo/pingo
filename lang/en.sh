# shellcheck shell=sh disable=SC2034
# pingo — English messages (reference language: every key must exist here).
#
# To create a translation, copy this file to ~/.config/pingo/lang/<code>.sh,
# translate the strings and run `pingo config lang <code>`.
# Keys you don't translate fall back to English automatically.
# Strings are printf formats: keep every %s, and write %% for a literal %.

PINGO_LANG_NAME="English"

# --- general ---------------------------------------------------------------
PINGO_MSG_USAGE='Usage: %s'
PINGO_MSG_CANCELLED='Cancelled.'
PINGO_MSG_NOT_FOUND='not found'
PINGO_MSG_EMPTY='No repositories yet.'
PINGO_MSG_EMPTY_HINT='Add one with %s'
PINGO_MSG_EMPTY_MENU_HINT='Press "a" to add the current directory.'
PINGO_MSG_COUNT_ONE='1 repository'
PINGO_MSG_COUNT_MANY='%s repositories'

# --- results -----------------------------------------------------------------
PINGO_MSG_ADDED='Added #%s %s → %s'
PINGO_MSG_REMOVED='Removed %s.'
PINGO_MSG_MOVED='Moved %s to position %s.'
PINGO_MSG_RENAMED='Renamed %s to %s.'
PINGO_MSG_PRUNED_ONE='Removed %s (%s)'
PINGO_MSG_PRUNED='Pruned %s missing repositories.'
PINGO_MSG_PRUNE_NOTHING='Every repository still exists. Nothing to prune.'
PINGO_MSG_LANG_SET='Language set to %s.'
PINGO_MSG_CONFIRM_REMOVE='Remove #%s %s? [y/N]'

# --- errors and warnings -------------------------------------------------------
PINGO_MSG_ERR_UNKNOWN_OPTION='Unknown option: %s (see pingo help)'
PINGO_MSG_ERR_NO_POSITION='There is no position %s (the list has %s).'
PINGO_MSG_ERR_NOT_FOUND='No repository named "%s". Run pingo ls to see the list.'
PINGO_MSG_ERR_AMBIGUOUS='More than one repository is called "%s". Use its number or give it an alias.'
PINGO_MSG_ERR_ALIAS_EMPTY='The alias cannot be empty.'
PINGO_MSG_ERR_ALIAS_NUMERIC='Invalid alias "%s": numbers are reserved for positions.'
PINGO_MSG_ERR_ALIAS_CHARS='Invalid alias "%s": no spaces, "|" or leading "-".'
PINGO_MSG_ERR_ALIAS_RESERVED='Invalid alias "%s": it is a pingo command.'
PINGO_MSG_ERR_ALIAS_TAKEN='The name "%s" is already used by #%s.'
PINGO_MSG_ERR_NOT_DIR='Not a directory: %s'
PINGO_MSG_ERR_DUP_PATH='%s is already registered as #%s (%s).'
PINGO_MSG_WARN_NOT_GIT='%s is not a git repository (added anyway).'
PINGO_MSG_ERR_SAVE='Could not write %s'
PINGO_MSG_ERR_MISSING_DIR='%s no longer exists at %s'
PINGO_MSG_HINT_PRUNE='Run "pingo prune" to remove missing repositories.'
PINGO_MSG_ERR_UNKNOWN_LANG='Unknown language "%s". Run pingo config lang to see the available ones.'
PINGO_MSG_ERR_NO_GIT='git was not found; install it and try again.'
PINGO_MSG_ERR_NOT_CLONE='%s is not a git clone; update it manually.'

# --- update ----------------------------------------------------------------------
PINGO_MSG_UPDATING='Updating pingo…'
PINGO_MSG_UPDATE_FAILED='Update failed.'
PINGO_MSG_UPDATED='pingo is up to date (v%s).'

# --- pull ------------------------------------------------------------------------
# The first %s is the repository, the second its default branch.
PINGO_MSG_PULL_UPDATED_ONE='%s: %s updated, 1 commit (%s → %s)'
PINGO_MSG_PULL_UPDATED_MANY='%s: %s updated, %s commits (%s → %s)'
PINGO_MSG_PULL_CURRENT='%s: %s already up to date'
PINGO_MSG_PULL_FAILED='%s: pull failed'

# --- pull: every repository -----------------------------------------------------
PINGO_MSG_PULL_SUMMARY='Summary: %s updated, %s already up to date, %s skipped, %s failed'
PINGO_MSG_PULL_SUMMARY_SKIPPED='%s: skipped (%s)'
PINGO_MSG_PULL_SUMMARY_SKIPPED_BARE='%s: skipped'
PINGO_MSG_PULL_SUMMARY_FAILED='%s: failed (%s)'
PINGO_MSG_PULL_SUMMARY_FAILED_BARE='%s: failed'

# --- help ------------------------------------------------------------------------
PINGO_MSG_HELP_TAGLINE='your faithful companion to jump between repositories'
PINGO_MSG_HELP_USAGE='Usage'
PINGO_MSG_HELP_MENU='open the interactive menu'
PINGO_MSG_HELP_GO='go straight to a repository'
PINGO_MSG_HELP_LS='list repositories'
PINGO_MSG_HELP_ADD='register a repository (at the end of the list)'
PINGO_MSG_HELP_RM='remove a repository from the list'
PINGO_MSG_HELP_MV='move a repository to another position'
PINGO_MSG_HELP_RENAME='change the alias of a repository'
PINGO_MSG_HELP_PRUNE='remove repositories that no longer exist'
PINGO_MSG_HELP_CONFIG='show settings and file locations'
PINGO_MSG_HELP_LANG='list languages or change the language'
PINGO_MSG_HELP_PULL='bring the default branch up to date with its remote'
PINGO_MSG_HELP_UPDATE='update pingo to the latest version'
PINGO_MSG_HELP_HELP='show this help'
PINGO_MSG_HELP_VERSION='show the version'
PINGO_MSG_HELP_MENU_KEYS='Menu keys'
PINGO_MSG_KEY_NAV='navigate'
PINGO_MSG_KEY_OPEN='go to the selected repository'
PINGO_MSG_KEY_JUMP='jump to a position'
PINGO_MSG_KEY_ADD='add the current directory'
PINGO_MSG_KEY_REMOVE='remove the selected repository'
PINGO_MSG_KEY_MOVE='move: pick it up, use ↑↓, drop with Enter'
PINGO_MSG_KEY_RENAME='rename (change alias)'
PINGO_MSG_KEY_SETTINGS='settings (language)'
PINGO_MSG_KEY_HELP='this help'
PINGO_MSG_KEY_QUIT='quit'
PINGO_MSG_PRESS_ANY_KEY='Press any key to go back.'

# --- menu ------------------------------------------------------------------------
PINGO_MSG_MOVE_MODE='moving'
PINGO_MSG_MORE_ABOVE='%s more'
PINGO_MSG_MORE_BELOW='%s more'
PINGO_MSG_F_OPEN='open'
PINGO_MSG_F_ADD='add'
PINGO_MSG_F_REMOVE='remove'
PINGO_MSG_F_MOVE='move'
PINGO_MSG_F_SETTINGS='settings'
PINGO_MSG_F_HELP='help'
PINGO_MSG_F_QUIT='quit'
PINGO_MSG_F_MOVE_ITEM='move'
PINGO_MSG_F_DROP='drop'
PINGO_MSG_F_CANCEL='cancel'
PINGO_MSG_F_NAVIGATE='navigate'
PINGO_MSG_F_SELECT='select'
PINGO_MSG_F_BACK='back'
PINGO_MSG_PROMPT_ALIAS='Alias for %s (optional, Enter to skip):'
PINGO_MSG_PROMPT_RENAME='New alias for %s (Enter to cancel):'
PINGO_MSG_SETTINGS_TITLE='Settings'
PINGO_MSG_SETTINGS_LANG='Language'
PINGO_MSG_SETTINGS_LANG_TITLE='Settings › Language'

# --- installer ---------------------------------------------------------------------
PINGO_MSG_INSTALL_TITLE='Installing pingo'
PINGO_MSG_INSTALL_LANG='Language: %s (change it anytime with "pingo config lang")'
PINGO_MSG_INSTALL_RC_QUESTION='Where should pingo be loaded?'
PINGO_MSG_INSTALL_RECOMMENDED='recommended'
PINGO_MSG_INSTALL_CHOICE='Choice [%s]:'
PINGO_MSG_INSTALL_INVALID='Invalid choice: %s'
PINGO_MSG_INSTALL_ALREADY='%s already loads pingo.'
PINGO_MSG_INSTALL_ADDED='Added pingo to %s'
PINGO_MSG_INSTALL_BASH_PROFILE='%s now loads ~/.bashrc'
PINGO_MSG_INSTALL_DONE='pingo is installed!'
PINGO_MSG_INSTALL_NEXT='Open a new terminal, or run:  source %s'
PINGO_MSG_INSTALL_TRY='Then try:  pingo add . my-repo  and  pingo'
PINGO_MSG_UNINSTALL_TITLE='Uninstalling pingo'
PINGO_MSG_UNINSTALL_REMOVED='Removed pingo from %s'
PINGO_MSG_UNINSTALL_NOTHING='No shell startup file was loading pingo.'
PINGO_MSG_UNINSTALL_ASK_DATA='Also delete your repository list and settings (%s)? [y/N]'
PINGO_MSG_UNINSTALL_DATA_REMOVED='Deleted %s'
PINGO_MSG_UNINSTALL_DATA_KEPT='Kept your data in %s'
PINGO_MSG_UNINSTALL_DONE='pingo was uninstalled. Open a new terminal to finish.'
PINGO_MSG_UNINSTALL_CODE_HINT='To delete the program files too:  rm -rf %s'
