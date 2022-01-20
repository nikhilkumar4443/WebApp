FROM openjdk:11-jdk-slim

ADD target/hello-world-app.jar hello-world-app.jar
ENTRYPOINT ["java", "-jar", "/hello-world-app.jar"]
EXPOSE 2222