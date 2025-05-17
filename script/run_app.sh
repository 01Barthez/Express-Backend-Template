#!/bin/bash
set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log() {
  echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

# Vérification si un environnement est spécifié
if [ -z "$1" ]; then
  warning "Aucun environnement spécifié. Utilisation de l'environnement de développement par défaut."
  ENV="dev"
else
  ENV="$1"
fi

# Validation de l'environnement
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
  error "Environnement non valide. Utilisez 'dev' ou 'prod'."
fi

# Configuration des fichiers docker-compose et .env en fonction de l'environnement
if [ "$ENV" == "dev" ]; then
  COMPOSE_FILE="docker-compose.dev.yml"
  ENV_FILE=".env.development"
  ENV_EXAMPLE=".env.development.example"
  log "Mode développement sélectionné."
else
  COMPOSE_FILE="docker-compose.prod.yml"
  ENV_FILE=".env"
  ENV_EXAMPLE=".env.example"
  log "Mode production sélectionné."
fi

# Vérification de la présence de Docker et Docker-compose
command -v docker >/dev/null 2>&1 || error "Docker n'est pas installé. Veuillez l'installer avant de continuer."
command -v docker-compose >/dev/null 2>&1 || error "Docker-compose n'est pas installé. Veuillez l'installer avant de continuer."

# Vérifier si l'utilisateur a les droits nécessaires
if [ "$(id -u)" != "0" ] && ! groups | grep -q '\bdocker\b'; then
  warning "Vous n'êtes pas root ou membre du groupe 'docker'. Vous pourriez rencontrer des problèmes de permissions."
  read -p "Continuer quand même? (y/n) " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# Vérifier si le fichier docker-compose existe
if [ ! -f "$COMPOSE_FILE" ]; then
  error "Fichier $COMPOSE_FILE non trouvé. Veuillez vérifier que vous êtes dans le bon répertoire."
fi

# Vérifier si .env existe pour l'environnement spécifié, sinon le créer à partir de l'exemple
if [ ! -f "$ENV_FILE" ]; then
  log "Fichier $ENV_FILE non trouvé, création à partir de $ENV_EXAMPLE..."
  if [ -f "$ENV_EXAMPLE" ]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    success "Fichier $ENV_FILE créé. Veuillez vérifier et modifier les valeurs si nécessaire."
    warning "Le fichier $ENV_FILE contient des valeurs par défaut. Pour des raisons de sécurité, modifiez les mots de passe avant de continuer."
    read -p "Appuyez sur Entrée pour continuer ou Ctrl+C pour annuler..."
  else
    error "Fichier $ENV_EXAMPLE non trouvé. Impossible de créer le fichier $ENV_FILE."
  fi
fi

# Vérifier si le dossier ssl existe et si les certificats sont présents
if [ ! -d "ssl" ]; then
  log "Création du dossier ssl..."
  mkdir -p ssl
  success "Dossier ssl créé."
else
  log "Dossier ssl trouvé."
fi

# Vérifier si des certificats SSL sont nécessaires
if grep -q "#.*listen 443 ssl" nginx.conf; then
  warning "La configuration HTTPS est commentée dans nginx.conf. L'application fonctionnera en mode HTTP uniquement."
else
  if [ ! -f "ssl/fullchain.pem" ] || [ ! -f "ssl/privkey.pem" ]; then
    warning "Les certificats SSL ne sont pas présents dans le dossier ssl. L'application pourrait ne pas démarrer correctement en mode HTTPS."
    
    if [ "$ENV" == "dev" ]; then
      read -p "Voulez-vous générer des certificats auto-signés pour le développement? (y/n) " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Génération de certificats auto-signés..."
        # Vérifier si openssl est installé
        command -v openssl >/dev/null 2>&1 || error "OpenSSL n'est pas installé. Veuillez l'installer avant de continuer."
        
        # Générer un certificat auto-signé
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
          -keyout ssl/privkey.pem -out ssl/fullchain.pem \
          -subj "/C=FR/ST=State/L=City/O=Organization/CN=localhost" \
          || error "Échec de la génération des certificats SSL."
        
        success "Certificats SSL auto-signés générés avec succès."
        warning "Ces certificats sont auto-signés et destinés uniquement au développement."
      fi
    else
      warning "En production, vous devez utiliser des certificats SSL valides. Veuillez les placer dans le dossier 'ssl'."
      read -p "Appuyez sur Entrée pour continuer sans HTTPS ou Ctrl+C pour annuler..."
    fi
  else
    log "Certificats SSL trouvés dans le dossier ssl."
  fi
fi

# Arrêter les conteneurs existants s'ils sont en cours d'exécution
log "Vérification des conteneurs existants..."
if docker-compose -f "$COMPOSE_FILE" ps -q | grep -q .; then
  log "Arrêt des conteneurs existants..."
  docker-compose -f "$COMPOSE_FILE" down || warning "Échec de l'arrêt des conteneurs existants. Tentative de continuer..."
  success "Conteneurs arrêtés."
else
  log "Aucun conteneur existant n'est en cours d'exécution pour cet environnement."
fi

# Construire les images Docker
log "Construction des images Docker pour l'environnement $ENV..."
docker-compose -f "$COMPOSE_FILE" build || error "Échec de la construction des images Docker."
success "Images Docker construites avec succès."

# Démarrer les conteneurs
log "Démarrage des conteneurs pour l'environnement $ENV..."
docker-compose -f "$COMPOSE_FILE" up -d || error "Échec du démarrage des conteneurs."
success "Conteneurs démarrés avec succès."

# Vérifier que tous les conteneurs sont en cours d'exécution
log "Vérification de l'état des conteneurs..."
sleep 5
RUNNING_CONTAINERS=$(docker-compose -f "$COMPOSE_FILE" ps -q | wc -l)
EXPECTED_CONTAINERS=$(docker-compose -f "$COMPOSE_FILE" config --services | wc -l)
if [ "$RUNNING_CONTAINERS" -ne "$EXPECTED_CONTAINERS" ]; then
  warning "Certains conteneurs ne sont pas en cours d'exécution. Vérification des logs..."
  docker-compose -f "$COMPOSE_FILE" logs
  error "Certains conteneurs n'ont pas démarré correctement. Veuillez vérifier les logs ci-dessus."
fi

# Afficher les conteneurs en cours d'exécution
docker-compose -f "$COMPOSE_FILE" ps

# Charger les variables d'environnement
source "$ENV_FILE"

# Afficher les URL d'accès
echo ""
success "==================================="
success "Application démarrée avec succès en environnement $ENV !"
success "==================================="
echo ""
log "URLs d'accès:"
HTTP_PORT=${NGINX_HTTP_PORT:-80}
HTTPS_PORT=${NGINX_HTTPS_PORT:-443}
echo -e "${GREEN}➜ HTTP:${NC} http://localhost:$HTTP_PORT"
if ! grep -q "#.*listen 443 ssl" nginx.conf; then
  echo -e "${GREEN}➜ HTTPS:${NC} https://localhost:$HTTPS_PORT"
fi
echo -e "${GREEN}➜ API:${NC} http://localhost:$HTTP_PORT/api"
echo -e "${GREEN}➜ Health Check:${NC} http://localhost:$HTTP_PORT/health"

# Afficher les URLs des outils d'administration si en mode développement
if [ "$ENV" == "dev" ]; then
  echo ""
  log "URLs des outils d'administration:"
  MONGO_EXPRESS_PORT=${MONGO_EXPRESS_PORT:-8081}
  REDIS_INSIGHT_PORT=${REDIS_INSIGHT_PORT:-8001}
  NPM_ADMIN_PORT=${NPM_ADMIN_PORT:-82}
  echo -e "${GREEN}➜ Mongo Express:${NC} http://localhost:$MONGO_EXPRESS_PORT"
  echo -e "${GREEN}➜ Redis Insight:${NC} http://localhost:$REDIS_INSIGHT_PORT"
  echo -e "${GREEN}➜ Nginx Proxy Manager:${NC} http://localhost:$NPM_ADMIN_PORT"
  echo -e "   (Identifiants par défaut - Email: admin@example.com, Mot de passe: changeme)"
fi

echo ""
log "Pour voir les logs de l'application:"
echo "docker-compose -f $COMPOSE_FILE logs -f app"
echo ""
log "Pour arrêter l'application:"
echo "docker-compose -f $COMPOSE_FILE down"
echo ""
