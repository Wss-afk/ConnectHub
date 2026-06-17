# ConnectHub

A full-stack real-time chat platform built with Spring Boot, Vue.js, WebSocket, and MySQL.

## Live Demo

🔗 Demo: https://connecthub-uvyk.onrender.com

## Features

### Real-Time Communication

* Real-time messaging using WebSocket (STOMP)
* Direct messaging between users
* Group chat support
* Online/offline user status
* Unread message tracking

### User Management

* User registration and authentication
* User profile management
* Avatar upload support
* Role-based permissions

### Administration

* Admin dashboard
* User moderation
* Group management
* Activity monitoring

### Additional Features

* File and image uploads
* Responsive design
* Read receipts and unread counters
* Persistent chat history

## Tech Stack

### Backend

* Java 21
* Spring Boot 3
* Spring Security
* Spring Data JPA
* WebSocket (STOMP)
* MySQL / H2

### Frontend

* Vue.js 3
* Vuex
* Vue Router
* Axios
* Bootstrap 5
* SockJS
* WebStomp

## Architecture

Frontend (Vue.js)
↓
REST API + WebSocket
↓
Spring Boot
↓
JPA/Hibernate
↓
MySQL / H2 Database

## Screenshots

(Add screenshots here)

## Local Development

### Backend

```bash
cd chatroom_backend
mvn spring-boot:run
```

### Frontend

```bash
cd chatroom_frontend
npm install
npm run serve
```

## Future Improvements

* Message reactions
* Push notifications
* End-to-end encryption
* Voice and video chat

## Author

Shanshui Wang

Final Degree Project (TFG)
