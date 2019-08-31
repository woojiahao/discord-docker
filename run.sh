#!/bin/bash
if [[ -z $BOT_TOKEN ]]; then 
	echo "Bot token must be added as an environment variable to your machine to execute this bot"
else
	docker run -e BOT_TOKEN=${BOT_TOKEN} -d discord-docker:latest
fi
