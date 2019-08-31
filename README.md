# discord-docker
Demo project for hosting a Discord bot written in Kotlin with Docker on Heroku

This project will use concepts such as multi-stage builds in Docker and hosting Docker applications in Heroku to deploy this Discord bot.

## Hosting the bot locally
As pre-requisites, you must have Docker installed. In my case, I'm running Docker on Manjaro linux. You should also create a Discord bot account through Discord's [developer portal.](https://discordapp.com/developers/docs/intro)

1. Clone this repository and navigate to the clone repository location

   ```bash 
   $ git clone https://github.com/woojiahao/discord-docker.git
   $ cd discord-docker
   ```

2. Initiatialise the repository as a Heroku application
   
   ```bash 
   $ heroku create <optional application name>
   ```

3. Create the docker image and verify whether the image is created
   
   ```bash
   $ docker build -t discord-docker .
   $ docker image ls
   ```

4. Once the image has been created, run the image, providing the bot token as an environment variable. Once it launches, verify that the container is running.
   
   ```bash
   $ docker run -e BOT_TOKEN=<BOT TOKEN> -d discord-docker:latest
   $ docker container ls
   ```

## Project composition
### `build.gradle`
The `build.gradle` straightforward, with the use of the `shadowJar` plugin to create the fat jar required for all library dependency. In order to prevent the exported jar from having differing names, we set the `archiveName` attribute of the plugin to always use the name `bot.${extension}`.

This means that even if we changed the version of the gradle file, the exported jar file is the same name so we don't need to modify our Dockerfile.

```groovy
plugins {
  id 'org.jetbrains.kotlin.jvm' version '1.3.41'
  id 'com.github.johnrengelman.shadow' version '5.0.0'
}

sourceCompatibility = 1.8
targetCompatibility = 1.8

group 'com.github.woojiahao'
version '1.0-SNAPSHOT'

repositories {
  mavenCentral()
  maven { url 'https://jitpack.io' }
  jcenter()
}

dependencies {''
  implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk8"
  implementation "com.gitlab.aberrantfox:Kutils:0.9.17"
}

compileKotlin {
  kotlinOptions.jvmTarget = "1.8"
}
compileTestKotlin {
  kotlinOptions.jvmTarget = "1.8"
}

sourceSets {
  main.java.srcDirs += 'src/main/kotlin/'
  test.java.srcDirs += 'src/test/kotlin/'
}

jar {
  manifest {
    attributes "Main-Class": "BotKt"
  }

  from {
    configurations.compile.collect {
      zipTree(it)
    }
  }
}

shadowJar {
  archiveName("bot.${extension}")
}
```

### `Dockerfile`
The `Dockerfile` is a little more interesting as it makes use of [multi-stage builds](https://docs.docker.com/v17.09/engine/userguide/eng-image/multistage-build/) to create a minimal Docker image. 

Our first image layer uses the official gradle images. We will label this layer as `builder`. In this layer, our goal is to create the jar file that will contain all our dependencies. We first access the image as the root user and start with our working directory labelled as `/builder`. We then add all of our files into the working directory and finally, we construct the fat jar using the `gradle shadowJar` command.

Then, we create another layer which will be the final layer that goes into the image. We first use the official Alpine linux image for OpenJDK 8. Then we create a working directory for our application labelled `/app`. Then we copy our fat jar from the `builder` layer to the our home directory. As soon as we are done, we then run the command to execute our fat jar and it will cause the Discord bot to launch.

Using Discord allows us to remain Gradle and Java version agnostic. This `Dockerfile` was taken and modified from the following article found [here.](https://www.richyhbm.co.uk/posts/kotlin-docker-spring-oh-my/)

```docker
FROM gradle:5.6.1-jdk8 AS builder
USER root
WORKDIR /builder
ADD . /builder
RUN gradle shadowJar

FROM openjdk:8-jre-alpine
WORKDIR /app
COPY --from=builder /builder/build/libs/bot.jar .
CMD ["java", "-jar", "bot.jar"]
```