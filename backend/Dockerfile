FROM dhi.io/maven:3-jdk21-debian13-dev AS build

WORKDIR /build

COPY pom.xml .
RUN mvn dependency:go-offline

COPY src src
RUN mvn clean package -DskipTests

FROM dhi.io/amazoncorretto:21-debian13-dev AS run

WORKDIR /app

COPY --from=build /build/target/*.jar /app/app.jar

# COPY ../key/apartment-building-manager-42925fb0f83f.json /app/service-account.json

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]