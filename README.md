# doxtend
A docker extender via shell wrapper

## Features

At this moment, the features are light. I wrote the very basics of this because I want to be able to update containers with the newest image without having to do it manually and invoke my docker-compose or dockerfile files. I have plans to extend it to do more things with more specifications in the future, but offer it up to anyone who might be in the same place I am.

There is a reason this is not a built-in feature for Docker and I'm fully aware of that fact. However, I also know that there are many times that I want to do things that aren't built in because they don't work for the masses, but that could work for the little guy. This is that project.

## Installation

1. Make sure you already have [jq](https://stedolan.github.io/jq/) and [Docker](https://docs.docker.com/get-docker/) installed.
2. Setup your `.env` file with the appropriate `INSTALL_DIR` and `DOCKER_PATH`. If you don't, we will attempt it for you. However, it's always better if you put in the front end effort - everybody gets what they want more often that way. ;)
3. Run `sudo ./install.sh` from the command line within the doxtend folder.

## Usage

This project provides a script for updating Docker containers with a few limited configurations. The script offers several command-line options to tailor the Docker environment according to your needs.

The easiest (and probably most common) way to use it is simply to give the command `docker upgrade my_container` and let it work. However, if you have some things that you want to modify or that aren't saved as environment variables when you initially created it, you have the option to do that as well.

### Options

* `-e` <env_var>: Set environment variables in the container. This option can be used multiple times.
* `-i` <image>: Specify the Docker image to use for the container.
* `-x`: Execute the Docker run command instead of printing it.
* `-q`: Enable quiet mode to minimize the script output.
* `-h`: Display help and exit.

_More options are in the works, but this is what I needed so this is what I started with..._

## LICENSE
This project is licensed under the [MIT License](LICENSE).

### MIT License Explained
The MIT License is a permissive open-source license that offers broad permissions to anyone who receives a copy of the licensed software. Here are the key aspects:

#### Permissions:
* Use: The software can be used for private or commercial purposes.
* Copy: You can make an unlimited number of copies.
* Modify: You can alter the software according to your needs.
* Merge: You can combine the software with other software.
* Publish: You can distribute copies to others.
* Distribute: You can give the software to anyone.
* Sub-license: You can allow others to grant new licenses on your work.

#### Conditions:
* Include Copyright: You must include the original copyright notice and the license text.
* Limitations:
* No Warranty: The software is provided "as is", without any warranty.
* No Liability: The authors are not liable for any claims or damages related to the software.

This license allows for maximum flexibility in using the software, while protecting the original authors from liability. It encourages open collaboration by allowing modifications and distribution under the same license terms.

-----
Version: 0.1.0