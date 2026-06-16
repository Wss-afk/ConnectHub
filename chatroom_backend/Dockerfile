# ---- Stage 1: Build with Maven ----
FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /app

# Copy pom.xml first to leverage Docker layer caching for dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
RUN mvn package -DskipTests -B

# ---- Stage 2: Runtime (minimal image) ----
FROM eclipse-temurin:21-jre

WORKDIR /app

# Copy only the built jar from the build stage
COPY --from=build /app/target/chatroom-backend-1.0.0.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
