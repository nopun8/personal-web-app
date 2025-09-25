#!/bin/bash

# S M Fahim Alam's Personal Web App - CSC Rahti Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_NAME="fahim-personal-app"
DEVELOPER_NAME="S M Fahim Alam"
REGISTRY_URL="image-registry.openshift-image-registry.svc:5000"
NAMESPACE="${NAMESPACE:-$(oc project -q 2>/dev/null || echo 'default')}"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_banner() {
    echo -e "${BLUE}"
    echo "============================================"
    echo "  S M Fahim Alam's Personal Web App"
    echo "  CSC Rahti Deployment Script"
    echo "============================================"
    echo -e "${NC}"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v oc &> /dev/null; then
        log_error "OpenShift CLI (oc) is not installed or not in PATH"
        exit 1
    fi
    
    if ! oc whoami &> /dev/null; then
        log_error "Not logged in to OpenShift cluster"
        log_info "Please login using: oc login https://api.2.rahti.csc.fi:6443"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
    log_info "Developer: $DEVELOPER_NAME"
    log_info "Current namespace: $NAMESPACE"
}

build_image() {
    log_info "Building Docker image for $DEVELOPER_NAME's app..."
    
    if [ ! -f "Dockerfile" ]; then
        log_error "Dockerfile not found in current directory"
        exit 1
    fi
    
    if ! oc get imagestream $PROJECT_NAME &> /dev/null; then
        log_info "Creating ImageStream for $PROJECT_NAME..."
        oc create imagestream $PROJECT_NAME
    fi
    
    if ! oc get buildconfig $PROJECT_NAME &> /dev/null; then
        log_info "Creating BuildConfig for $PROJECT_NAME..."
        oc new-build --name=$PROJECT_NAME --binary --strategy=docker
    fi
    
    log_info "Starting binary build for $DEVELOPER_NAME's app..."
    oc start-build $PROJECT_NAME --from-dir=. --follow
    
    log_success "Image built successfully for $DEVELOPER_NAME's personal app"
}

deploy_application() {
    log_info "Deploying $DEVELOPER_NAME's personal application to Rahti..."
    
    log_info "Updating deployment with correct image path..."
    sed "s|NAMESPACE|${NAMESPACE}|g" k8s/deployment.yaml > k8s/deployment-updated.yaml
    
    log_info "Applying ConfigMap and Secrets..."
    oc apply -f k8s/configmap.yaml
    
    log_info "Applying Deployment..."
    oc apply -f k8s/deployment-updated.yaml
    
    log_info "Applying Service and Route..."
    oc apply -f k8s/service.yaml
    
    log_info "Applying HPA (if supported)..."
    oc apply -f k8s/hpa.yaml || log_warning "HPA might not be supported in this cluster"
    
    log_info "Applying Storage and Network policies..."
    oc apply -f k8s/storage-and-network.yaml || log_warning "Some resources might not be supported"
    
    rm -f k8s/deployment-updated.yaml
    
    log_success "$DEVELOPER_NAME's application deployed successfully"
}

wait_for_deployment() {
    log_info "Waiting for $DEVELOPER_NAME's app deployment to be ready..."
    
    oc rollout status deployment/$PROJECT_NAME --timeout=300s
    
    log_success "$DEVELOPER_NAME's app deployment is ready"
}

show_access_info() {
    log_info "Getting access information for $DEVELOPER_NAME's app..."
    
    ROUTE_URL=$(oc get route $PROJECT_NAME-route -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
    
    if [ -n "$ROUTE_URL" ]; then
        echo -e "${GREEN}"
        echo "============================================"
        echo "  $DEVELOPER_NAME's Personal Web App"
        echo "============================================"
        echo -e "${NC}"
        log_success "Application is accessible at: https://$ROUTE_URL"
        log_info "Health check: https://$ROUTE_URL/health"
        log_info "Name API (MAIN REQUIREMENT): https://$ROUTE_URL/api/name"
        log_info "System info: https://$ROUTE_URL/info"
        log_info "Portfolio: https://$ROUTE_URL/api/portfolio"
        echo ""
        log_info "Main API endpoint for identification: /api/name"
        log_info "This endpoint returns: {\"name\": \"$DEVELOPER_NAME\", ...}"
    else
        log_warning "Could not determine route URL. Check manually with: oc get routes"
    fi
    
    log_info "Pod status:"
    oc get pods -l app=$PROJECT_NAME
}

cleanup() {
    log_warning "Cleaning up $DEVELOPER_NAME's app resources..."
    
    read -p "Are you sure you want to delete all resources for $DEVELOPER_NAME's app? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        oc delete all,configmap,secret,pvc,networkpolicy,hpa -l app=$PROJECT_NAME
        oc delete imagestream,buildconfig $PROJECT_NAME 2>/dev/null || true
        log_success "Resources cleaned up for $DEVELOPER_NAME's app"
    else
        log_info "Cleanup cancelled"
    fi
}

show_help() {
    show_banner
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy    Build and deploy the application (default)"
    echo "  build     Build the Docker image only"
    echo "  status    Show deployment status"
    echo "  logs      Show application logs"
    echo "  cleanup   Remove all deployed resources"
    echo "  help      Show this help message"
    echo ""
    echo "Developer: $DEVELOPER_NAME"
    echo "Main API endpoint: /api/name (returns developer name for identification)"
}

show_logs() {
    log_info "Showing $DEVELOPER_NAME's application logs..."
    oc logs -l app=$PROJECT_NAME --tail=100 -f
}

show_status() {
    log_info "$DEVELOPER_NAME's app deployment status:"
    echo ""
    
    echo "Pods:"
    oc get pods -l app=$PROJECT_NAME
    echo ""
    
    echo "Services:"
    oc get svc -l app=$PROJECT_NAME
    echo ""
    
    echo "Routes:"
    oc get routes -l app=$PROJECT_NAME
    echo ""
    
    echo "HPA:"
    oc get hpa -l app=$PROJECT_NAME 2>/dev/null || echo "No HPA found"
    
    ROUTE_URL=$(oc get route $PROJECT_NAME-route -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
    if [ -n "$ROUTE_URL" ]; then
        echo ""
        log_info "Quick links:"
        log_info "Main app: https://$ROUTE_URL"
        log_info "Name API: https://$ROUTE_URL/api/name"
        log_info "Health: https://$ROUTE_URL/health"
    fi
}

main() {
    local command=${1:-deploy}
    
    show_banner
    
    case $command in
        deploy)
            check_prerequisites
            build_image
            deploy_application
            wait_for_deployment
            show_access_info
            ;;
        build)
            check_prerequisites
            build_image
            ;;
        status)
            check_prerequisites
            show_status
            ;;
        logs)
            check_prerequisites
            show_logs
            ;;
        cleanup)
            check_prerequisites
            cleanup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"