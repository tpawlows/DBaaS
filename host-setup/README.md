# host-setup
Setup your developer's machine, so you can easily deploy your DBaaS and manage it from there.
## setup-wsl.sh
Works on WSL version 2 with Ubuntu 20.04 LTS but should work also on normal Ubuntu installation.
1. Create config called `.dbaas.configuration` in your home directory.
	- Content of a `.dbaas.configuration` file:
	```bash
	aws_access_key: 	"1234567890qwe"
	aws_secret_key: 	"1234567890qwerty12309876321"
	gh_login: 			"Username"							# your github.com username
	gh_pat: 			"ghp_1234567890qwerty12309876321" 	# Personal Access Token for github.com
	grafana_password: 	"example_password"  				# Password for deployed grafana admin user
	pg_password: 		"example_password"  				# Password for deployed postgres cluster
	```
	This file will store sensitive data for accessing github, aws, deployed services and Postgres DB, and will be used during WSL machine configuration.
2. Run command.
	```bash
	https://raw.githubusercontent.com/tpawlows/dbaas/master/host-setup/setup-wsl.sh | bash
	```
