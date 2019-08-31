FROM gradle:5.6.1-jdk8 AS builder
USER root
WORKDIR /builder
ADD . /builder
RUN gradle shadowJar

FROM openjdk:8-jre-alpine
WORKDIR /app
COPY --from=builder /builder/build/libs/bot.jar .
CMD ["java", "-jar", "bot.jar"]