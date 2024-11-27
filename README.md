# setup.sh
This bash script will set up a 'work' and 'personal' directory in the users home directory and generate two ssh keys which the user can add to their github accounts. It will also configure the system to to use the correct ssh key depending on which directory they are in.

## Assumptions
This script assumes a fresh Ubuntu install and that the user is a non-root user with sudo privledges.

## Instructions

1) Clone setup.sh
```bash
git clone git@github.com:dariushaskell/setup.sh.git
```
2) Make script executable 
```bash
chmod +x ~/setup.sh
```
3) Execute script
```bash
./setup.sh

```
4) Restart your terminal.
