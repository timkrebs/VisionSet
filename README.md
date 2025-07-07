# VisionSet.app – Microservices Architecture Plan

## Overview

**VisionSet.app** is a microservices-based architecture for the FilmMaker AI web application. The platform empowers filmmakers and writers with AI-powered story and idea generation, script writing, image-based search, and a collaborative board system for collecting and sharing ideas. Premium plans offer AI credits, automated suggestions, and “Magic Boards” for visual pitch generation. Each service is a separate Python app (e.g., FastAPI), containerized with Docker, and deployed on Azure Kubernetes Service (AKS) for scalability and isolation.

---

## Key Features

- **Story & Script Generation:** AI-assisted story idea and screenplay creation (via OpenAI GPT models).
- **Image Search:** Upload an image (or use sample images) to find similar visuals (using image embeddings).
- **Boards System:** Users create boards (collections of images and text), which can be saved, downloaded, and shared with others.
- **AI Suggestions:** The system recommends similar images and related board content using AI (e.g. vector similarity or content-based filtering).
- **Paid Plans:** Grant users AI credits to boost creativity. Premium features include additional AI suggestions and automatic “Magic Boards” generated from a text pitch.
- **Authentication:** Login/signup via Clerk’s service for secure user management.

## Proposed Microservices

- **Authentication Service:** Handles user login/signup and sessions. We will use Clerk (a hosted auth provider) with its Python SDK ￼ to manage users and tokens. This service verifies JWTs and provides user context to other services.
- **User/Credit Service:** Manages user profiles, subscription tiers, and AI credit balances. Tracks usage of AI calls and decrements credits. This service uses its own database to isolate billing logic and enforce quotas (one service–one database principle ￼).
- **Content Service (Story & Script):** Provides endpoints to generate story ideas and scripts by calling the OpenAI API. It interprets user prompts (e.g. scene outlines) and returns AI-generated text. This service encapsulates LLM logic and limits (deducting credits from the User Service per call).
- **Image Service:** Handles image uploads and processing. When a user uploads an image, this service saves it to scalable object storage (e.g. AWS S3 or Azure Blob) and stores metadata (file path, owner, tags) in its database. It also generates a vector embedding for each image (using a vision model or OpenAI’s CLIP) and writes that embedding (with image ID) into a vector database for similarity search.
- **Search Service:** Accepts an image or image URL query and returns similar images. It queries the vector database (e.g. Qdrant or Pinecone) to find nearest neighbors of the query embedding. It then returns those images (or board elements) along with metadata to the frontend. This decouples search logic from the raw image storage.
- **Board Service:** Manages “boards” – collections of images and text entries. It supports creating, updating, and deleting boards, adding/removing items, and generating a shareable link. Boards can be downloaded (e.g. exported as PDF or ZIP). Each board references image IDs and text IDs stored by other services. This service has its own database of boards.
- **Recommendation Service:** Offers AI-driven recommendations within boards. For example, given a board’s current images/text, it suggests related images or story prompts. It might use embeddings (from the Image/Content services) and simple ML models to find related content. This is similar to recommendation engines (content-based filtering) and can subscribe to events from other services to update suggestion data.
- **Magic Board Service:** Special service for “Magic Boards” (visual pitch). Given a text pitch or story summary, it generates concept art or scene images (e.g. via OpenAI’s DALL·E or Stable Diffusion). The resulting images are returned as a new board. This service is heavy on AI calls and also consumes credits.
- **(Future) Collaboration Service:** Though not in the initial version, we plan to add real-time collaboration. This would be a WebSocket-based service (or use Reflex’s built-in real-time features) that lets multiple users edit a board simultaneously.

Each microservice is independently deployable in its own Docker container, communicating via REST/HTTP or gRPC. We will follow the microservices best practice of one service–one database ￼ to avoid tight coupling. Services share data only through APIs or messaging. For example, the Image Service only shares image URLs and IDs with the Board Service; it never directly exposes its database. This aligns with the recommended pattern that “two services should not share a data store”.

## Technical Stack & Tools

- **Backend (Python):** Use FastAPI (or Flask) for each microservice. FastAPI is lightweight, high-performance, and supports async calls and automatic OpenAPI docs. Each service has its own codebase and can be tested/deployed independently.
- **Frontend (Python/Reflex):** Use the Reflex framework to build the UI entirely in Python. Reflex compiles Python UI code into a React-based single-page app and uses WebSockets to sync events and state with the backend. This means our UI logic and components are written in Python (with minimal JavaScript), streamlining development. The example Reflex architecture (below) shows how the Python State is pushed/pulled via WebSockets ￼:
  Figure: Reflex app architecture – frontend React UI communicates with Python/FastAPI backend via WebSockets.
- **Authentication:** Clerk for auth UI (login/signup) and session management. On the backend, we use Clerk’s Python SDK to validate tokens. This offloads secure user management to a third party, simplifying our auth microservice.
- **Databases:** Each service chooses the best storage:
  - Relational DB (PostgreSQL or MySQL) or document DB (MongoDB) for user, board, and transaction data.
  - Object storage (S3/Azure Blob) for binary images, not inside the DB. (Following best practice: store images in a filesystem or object store and keep only paths in the DB.)
  - Vector DB (e.g. Qdrant) for image embeddings. Qdrant (or Pinecone) provides a REST API to store high-dimensional vectors and perform fast similarity search. We’ll insert each image’s embedding and metadata (tags, owner) here.
- **Containerization & Orchestration:** Dockerize every service (“single-service containers”). Deploy to AKS (Azure Kubernetes Service) with Kubernetes orchestration. We follow the practice of packaging each service as its own container for isolated scaling. Kubernetes will handle load balancing, scaling, and high availability of these containers. For example, we can run multiple instances of the Content Service behind a Deployment. Using AKS and Helm charts allows rolling upgrades and easy scaling.
- **API Gateway / Ingress:** Use an API Gateway or Kubernetes Ingress (e.g. NGINX) to route external requests to the appropriate service. The Reflex frontend communicates with services via this gateway.
- **Async Communication:** For tasks like image embedding or sending notifications, use an async message queue (e.g. RabbitMQ or Kafka). For example, when an image is uploaded, the Image Service can publish an event (“new image”), and a worker can asynchronously compute embeddings. This keeps the upload API fast.
- **Logging & Monitoring:** Use centralized logging (ELK stack or Azure Monitor) and health checks. Each service reports metrics (e.g. via Prometheus) so we can monitor performance.

## Image Storage and Search

We will not store raw images in a SQL database (it’s costly and inefficient ￼). Instead, uploaded images are placed in an object store (and served via CDN). The database for the Image Service stores only metadata (file location, owner, tags) and a generated embedding. For search-by-image, we use the vector DB approach: convert every image to a fixed-length vector (using an AI model) and insert it into Qdrant. Queries come in as images (converted to vectors) or keywords, and we perform nearest-neighbor search in Qdrant to find similar images. This follows modern “AI search” patterns – Qdrant’s docs highlight using vectors to make search for unstructured data efficient.

## Microservices Data Design

Each service has its own private datastore. For example, the Content Service might use PostgreSQL for story/script records, while the Image Service uses a separate database. This prevents schema coupling. If one service needs data from another, it must call its API (or receive an event). This aligns with the Azure microservices guidance that “two services should not share a data store”.

For example, the Board Service will never directly query the Content DB; it only stores references (e.g. board item IDs). If it needs story details, it calls the Content Service’s API. This ensures modularity and independent scalability. In short, we embrace polyglot persistence: use the best database for each domain (text DB for content, key-value or cache for sessions, vector DB for embeddings).

## Deployment Strategy

We containerize each service (using Docker) and deploy on AKS. We follow the pattern of one container per service. For example, the Content Service runs in a FastAPI container, the Image Service in another, etc. Kubernetes manages these pods. AKS provides a managed control plane and integrates with Azure Container Registry (for images) and Azure Pipelines (CI/CD). We use CI (e.g. GitHub Actions) to build and push Docker images, and Helm charts to deploy/upgrade on AKS. Kubernetes will handle load balancing and auto-scaling – if one service is under heavy load (e.g. many OpenAI requests), we can increase its replicas independently.

## Future Enhancements

- **Real-time Collaboration:** Later, we plan a WebSocket or WebRTC service so multiple users can edit a board together. Reflex has real-time components, so we might integrate a pub/sub (e.g. through Ably or Socket.IO) for live updates.
- **Media Expansion:** Support video and audio in boards (not just text/image) for storyboarding.
- **Advanced AI:** Fine-tune custom GPT models on user-provided scripts, or add voice-to-text for scripts.
- **Analytics:** Track usage patterns to improve recommendations (e.g. if many users link similar images, use that data).



## Description

FilmMaker AI helps filmmakers and writers find and create stories by leveraging AI. Users can generate story ideas and scripts using natural language prompts. They can upload or search by image to gather visual inspiration. Ideas are organized into sharable “boards” (mood boards / storyboards) that combine images and text. The app also provides AI-powered recommendations of related images and story concepts. A clean black-and-white UI (built with the Reflex framework) keeps the focus on content. User accounts and authentication are handled by Clerk. Premium subscribers get extra features: 100 AI credits (for extra OpenAI queries), automated AI suggestions, and “Magic Boards” (turn a text pitch into a visual storyboard).


## Future Work

- Add real-time collaboration on boards (e.g. viaWebSockets).
- Support multimedia (video/audio) in ideas.
- Enhance AI (fine-tune models, analytics onusage).
- Integrate social features (comments, likes onboards).

## References

- Microservices pattern: “small independent services… interact over APIs” ￼; each service with its own database.
- FastAPI & Reflex docs for Python full-stack development ￼.
- Image handling best practices: store files in object storage, not as DB blobs. Use vector DB (Qdrant) for image similarity search.
- Authentication: Clerk Python SDK documentation.
- Container orchestration: Kubernetes for high availability and scaling ￼; one-container-per-service deployment.