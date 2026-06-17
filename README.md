# ConnectHub

A full-stack real-time chat platform built with Spring Boot, Vue.js, WebSocket, and MySQL.

<<<<<<< HEAD
## Live Demo

🔗 Demo: https://connecthub-uvyk.onrender.com
=======
**Live Demo**: [https://connecthub-uvyk.onrender.com/](https://connecthub-uvyk.onrender.com/)

## 🚀 Features

### Core Chat Functionality
- **Real-time Messaging**: Powered by WebSocket (STOMP) for instant communication.
- **Direct & Group Chats**: Create groups, invite members, or chat one-on-one.
- **Read Status & Unread Counts**: 
  - Tracks the last read message for each user in every group.
  - Displays accurate unread message counters in the sidebar.
- **User Status**: Real-time Online/Offline status indicators.
- **File & Image Sharing**: Upload avatars, share images and files in conversations.
- **Event Management**: Create and manage events within the application.
>>>>>>> 16397f9 (docs(readme): 重构并扩展项目文档内容)

## Features

<<<<<<< HEAD
### Real-Time Communication
=======
### Technical Highlights
- **Responsive UI**: Built with Vue 3 and Bootstrap 5 for mobile and desktop support.
- **Secure Authentication**: Spring Security integration with role-based access control.
- **Flexible Database**: H2 in-memory database by default (zero-config), with MySQL support for production.
- **Docker Deployment**: Multi-stage Docker build optimized for cloud hosting.
- **SPA Architecture**: Frontend served directly by Spring Boot as a Single Page Application.
>>>>>>> 16397f9 (docs(readme): 重构并扩展项目文档内容)

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
<<<<<<< HEAD

* Java 21
* Spring Boot 3
* Spring Security
* Spring Data JPA
* WebSocket (STOMP)
* MySQL / H2

### Frontend
=======
- **Framework**: Spring Boot 3.2.5
- **Language**: Java 21
- **Database**: H2 (default) / MySQL 8.0 (production)
- **ORM**: Spring Data JPA
- **WebSocket**: Spring WebSocket (STOMP)
- **Security**: Spring Security

### Frontend
- **Framework**: Vue.js 3
- **State Management**: Vuex
- **Routing**: Vue Router
- **HTTP Client**: Axios
- **WebSocket Client**: `webstomp-client` / `sockjs-client`
- **Styling**: Bootstrap 5
- **Progress Indicator**: NProgress
>>>>>>> 16397f9 (docs(readme): 重构并扩展项目文档内容)

* Vue.js 3
* Vuex
* Vue Router
* Axios
* Bootstrap 5
* SockJS
* WebStomp

<<<<<<< HEAD
## Architecture
=======
Ensure you have the following installed:
- **Java Development Kit (JDK) 21**
- **Node.js** (v16+) & **npm**
- **Maven** (3.9+)

*Optional:*
- **MySQL Server** (if using MySQL instead of H2)
- **Docker** (for containerized deployment)
>>>>>>> 16397f9 (docs(readme): 重构并扩展项目文档内容)

Frontend (Vue.js)
↓
REST API + WebSocket
↓
Spring Boot
↓
JPA/Hibernate
↓
MySQL / H2 Database

<<<<<<< HEAD
## Screenshots

(Add screenshots here)

## Local Development

### Backend
=======
### 1. Clone the Repository
>>>>>>> 16397f9 (docs(readme): 重构并扩展项目文档内容)

```bash
git clone <repository-url>
cd TFG21
```

<<<<<<< HEAD
### Frontend
=======
### 2. Frontend Build
>>>>>>> 16397f9 (docs(readme): 重构并扩展项目文档内容)

```bash
cd chatroom_frontend
npm install
npm run build
```

### 3. Copy Frontend to Backend Static Resources

**Linux / macOS:**
```bash
cp -r chatroom_frontend/dist/* chatroom_backend/src/main/resources/static/
```

**Windows (PowerShell):**
```powershell
Copy-Item -Recurse -Force chatroom_frontend\dist\* chatroom_backend\src\main\resources\static\
```

### 4. Backend Setup

```bash
cd chatroom_backend
mvn clean package -DskipTests
java -jar target/chatroom-backend-1.0.0.jar
```

The application will start on `http://localhost:8080`.

### Database Configuration

By default, the application uses an **H2 in-memory database** (no setup required). To use MySQL instead, set the following environment variables:

| Variable | Default (H2) | MySQL Example |
|---|---|---|
| `DATABASE_URL` | `jdbc:h2:mem:chatroom;DB_CLOSE_DELAY=-1` | `jdbc:mysql://localhost:3306/chatroom` |
| `DB_USERNAME` | `sa` | `root` |
| `DB_PASSWORD` | *(empty)* | `yourpassword` |
| `DB_DRIVER` | `org.h2.Driver` | `com.mysql.cj.jdbc.Driver` |

When using H2, the console is available at `http://localhost:8080/h2-console`.

### Development Mode (Separate Servers)

For frontend development with hot reload:

```bash
cd chatroom_frontend
npm run serve
```
<<<<<<< HEAD
=======

The dev server will be accessible at `http://localhost:8081`.

## 🐳 Docker Deployment

```bash
cd chatroom_backend
docker build -t connecthub .
docker run -p 8080:8080 connecthub
```

For MySQL in Docker:
```bash
docker run -p 8080:8080 \
  -e DATABASE_URL=jdbc:mysql://host.docker.internal:3306/chatroom \
  -e DB_USERNAME=root \
  -e DB_PASSWORD=yourpassword \
  -e DB_DRIVER=com.mysql.cj.jdbc.Driver \
  connecthub
```
>>>>>>> 16397f9 (docs(readme): 重构并扩展项目文档内容)

## Future Improvements

<<<<<<< HEAD
* Message reactions
* Push notifications
* End-to-end encryption
* Voice and video chat

## Author

Shanshui Wang

Final Degree Project (TFG)
=======
### Read Status Tracking
The application uses a dedicated `GroupReadStatus` entity to efficiently track unread messages without scanning the entire message history.
- **Entity**: `com.chatroom.entity.GroupReadStatus`
- **Logic**: Stores the `lastReadMessageId` for a unique pair of `userId` and `groupId`.
- **Endpoints**: `ChatController` handles `/unread-count` and `/group/mark-read` to update status in real-time.

### WebSocket Events
- **Backend**: `WebSocketEventListener` tracks session connects/disconnects to manage online user lists.
- **Frontend**: Subscribes to `/topic/public` (global events) and `/user/queue/messages` (private updates).

### SPA Forwarding
- `SpaForwardController` forwards unknown routes to `index.html`, enabling Vue Router's client-side navigation.

## 📂 Project Structure

```
TFG21/
├── chatroom_backend/              # Spring Boot Server
│   ├── src/main/java/com/chatroom/
│   │   ├── config/                # Security, WebSocket, CORS, SPA
│   │   ├── controller/            # REST Controllers
│   │   ├── dto/                   # Data Transfer Objects
│   │   ├── entity/                # JPA Entities
│   │   ├── repository/            # Spring Data Repositories
│   │   ├── service/               # Business Logic
│   │   └── websocket/             # WebSocket Event Handlers
│   ├── src/main/resources/
│   │   ├── static/                # Frontend build output
│   │   └── application.yml        # Application config
│   ├── Dockerfile                 # Multi-stage Docker build
│   └── pom.xml                    # Maven config
├── chatroom_frontend/             # Vue.js Client
│   ├── src/
│   │   ├── views/                 # Pages (Chat, Admin, Login, Events)
│   │   ├── components/            # Reusable UI Components
│   │   ├── store/                 # Vuex State Management
│   │   ├── services/              # API & WebSocket Services
│   │   └── router/                # Vue Router config
│   └── package.json
└── README.md
```

## 👤 Default Admin Account

| Username | Password |
|---|---|
| `superadmin` | `admin123` |
>>>>>>> 16397f9 (docs(readme): 重构并扩展项目文档内容)
