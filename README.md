# `cluster_helper` ruby gem

The `cluster_helper` gem tries to normalize information coming
from slurm to help navigate information about current and past jobs,
users, accounts, and account members. To this end, there are a few
important classes in it's data model:

* `User`: a user known to slurm. This user has jobs and accounts;
* `ActiveJob`: a job that is either pending (waiting) or running;
* `InactiveJob`: a job that is done (not running or pending);
* `Account`: represents an account. An account has jobs and members;
* `AccountMember`: like a user, only tied to an account.

## `job_console`

These classes come together to make the tool `job_console` that
allows the user to explore jobs/accounts/users in a friendly
console-based (REPL) tool. Typing `help` at the console tells you
most of the commands.
