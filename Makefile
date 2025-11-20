# Aetheria Local Development Makefile

.PHONY: help build start stop restart logs clean verify test-api reset-db

# Default target
help: ## Show this help message
	@echo "Aetheria Local Development Commands"
	@echo "=================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Build and start services
build: ## Build all Docker images
	docker-compose build

start: ## Start all services
	@echo "🚀 Starting Aetheria services..."
	docker-compose up -d
	@echo "✅ Services started. Run 'make verify' to check status."

stop: ## Stop all services
	@echo "🛑 Stopping Aetheria services..."
	docker-compose down
	@echo "✅ Services stopped."

restart: ## Restart all services
	@echo "🔄 Restarting Aetheria services..."
	docker-compose restart
	@echo "✅ Services restarted."

# Development commands
dev: ## Start services and follow logs
	docker-compose up -d
	docker-compose logs -f

logs: ## View logs from all services
	docker-compose logs -f

logs-%: ## View logs from specific service (e.g., make logs-auth-service)
	docker-compose logs -f $*

# Verification and testing
verify: ## Verify that all services are running correctly
	@echo "🔍 Verifying Aetheria services..."
	@if command -v pwsh >/dev/null 2>&1; then \
		pwsh -File scripts/verify-local-setup.ps1; \
	elif [ -f scripts/verify-local-setup.sh ]; then \
		chmod +x scripts/verify-local-setup.sh && ./scripts/verify-local-setup.sh; \
	else \
		echo "⚠️  No verification script available for your platform"; \
	fi

test-api: ## Test all API health endpoints
	@echo "🧪 Testing API endpoints..."
	@for port in 3001 3002 3003 3004; do \
		echo "Testing service on port $$port:"; \
		curl -s -f http://localhost:$$port/health | jq . || echo "❌ Service on port $$port failed"; \
	done

# Database management
reset-db: ## Reset database with fresh data
	@echo "🗃️  Resetting database..."
	docker-compose stop db-setup video-seeder
	docker-compose down mongodb redis
	docker volume rm -f aetheria_mongodb_data aetheria_redis_data
	docker-compose up -d mongodb redis
	@echo "⏳ Waiting for database to be ready..."
	sleep 10
	docker-compose up -d db-setup
	docker-compose up -d video-seeder
	@echo "✅ Database reset complete."

# Service management
restart-%: ## Restart specific service (e.g., make restart-auth-service)
	docker-compose restart $*

rebuild-%: ## Rebuild and restart specific service (e.g., make rebuild-auth-service)
	docker-compose up -d --build $*

# Utility commands
clean: ## Clean up Docker resources
	@echo "🧹 Cleaning up Docker resources..."
	docker-compose down -v
	docker system prune -f
	docker volume prune -f
	@echo "✅ Cleanup complete."

status: ## Show status of all containers
	@echo "📊 Container Status:"
	@echo "==================="
	docker-compose ps

health: ## Show health status of all containers
	@echo "🏥 Health Status:"
	@echo "================"
	@for container in $$(docker-compose ps -q); do \
		name=$$(docker inspect --format='{{.Name}}' $$container | sed 's|/||'); \
		health=$$(docker inspect --format='{{.State.Health.Status}}' $$container 2>/dev/null || echo "no healthcheck"); \
		echo "$$name: $$health"; \
	done

# Access services
shell-%: ## Access shell in specific service (e.g., make shell-auth-service)
	docker-compose exec $* sh

mongo: ## Access MongoDB shell
	docker-compose exec mongodb mongosh -u admin -p password123 streamingapp

redis-cli: ## Access Redis CLI
	docker-compose exec redis redis-cli

# URLs and access
urls: ## Show all service URLs
	@echo "🔗 Service URLs:"
	@echo "==============="
	@echo "Web Frontend:     http://localhost"
	@echo "Auth Service:     http://localhost:3001"
	@echo "Streaming Service: http://localhost:3002"
	@echo "Chat Service:     http://localhost:3003"
	@echo "Core API Service: http://localhost:3004"
	@echo "MinIO Console:    http://localhost:9001"
	@echo ""
	@echo "👤 Test Accounts:"
	@echo "Admin: admin@aetheria.com / admin123"
	@echo "User:  user@aetheria.com / admin123"

open: ## Open application in browser (macOS/Linux)
	@if command -v open >/dev/null 2>&1; then \
		open http://localhost; \
	elif command -v xdg-open >/dev/null 2>&1; then \
		xdg-open http://localhost; \
	else \
		echo "Please open http://localhost in your browser"; \
	fi

# Quick setup
setup: build start ## Build and start all services (one command setup)
	@echo "⏳ Waiting for services to be ready..."
	@sleep 30
	@make verify

# Full reset
reset: clean setup ## Complete reset: clean everything and start fresh

# Production helpers
prod-check: ## Check if setup is production-ready
	@echo "🔒 Production Readiness Check:"
	@echo "============================="
	@echo "⚠️  This setup is for LOCAL DEVELOPMENT only!"
	@echo ""
	@echo "For production, ensure:"
	@echo "- Change default passwords"
	@echo "- Use external databases"
	@echo "- Configure SSL/TLS"
	@echo "- Use production storage"
	@echo "- Set up monitoring"
	@echo "- Use container orchestration"