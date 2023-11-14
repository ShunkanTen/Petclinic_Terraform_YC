FROM maven

WORKDIR ./spring-petclinic

COPY ./src ./src
COPY ./pom.xml ./pom.xml

RUN mvn package

FROM openjdk:17.0.2-jdk-oracle

COPY --from=0 ./spring-petclinic/target/*.jar /opt/java-app.jar

ENTRYPOINT [ "java", "-jar", "/opt/java-app.jar" ]
