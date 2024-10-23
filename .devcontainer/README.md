# Ahoi, welcome on board!

## Environment
As environment variables often contain sensitive information like API or license keys it is recomended to not have them version controlled:
~~~.gitignore
# never check in .env files, add to .gitignore:
*.env
~~~

To configure your local environment, checkout the repo and create a file called `devcontainer.env` inside the `.devcontainer` folder.