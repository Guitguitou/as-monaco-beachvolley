# Configuration Redis pour le Cache

## 🚀 Démarrage Rapide

### Développement Local
```bash
# Option 1: Avec Docker (recommandé)
./bin/start-redis

# Option 2: Installation manuelle
# macOS
brew install redis && brew services start redis

# Ubuntu/Debian
sudo apt install redis-server && sudo systemctl start redis
```

### Production
Assurez-vous que la variable d'environnement `REDIS_URL` est définie :
```bash
export REDIS_URL="redis://your-redis-server:6379/0"
```

## 📋 Configuration

### Variables d'Environnement
- `REDIS_URL`: URL de connexion Redis (défaut: `redis://localhost:6379/0`)

### Cache Configuration
- **Namespace**: `as_monaco_beach_volley_cache`
- **Expiration**: 1 heure par défaut
- **Environnements**:
  - **Development**: Cache mémoire (plus simple)
  - **Production**: Redis (plus robuste)

## 🔧 Utilisation

Le cache est automatiquement utilisé par les services de reporting :
- `Reporting::Kpis`
- `Reporting::Revenue`
- `Reporting::CoachSalaries`
- `Reporting::Alerts`

## 🐛 Dépannage

### Redis non accessible
```bash
# Vérifier la connexion
redis-cli ping

# Vérifier les logs
docker-compose -f docker-compose.redis.yml logs redis
```

### Cache ne fonctionne pas
1. Vérifier que Redis est démarré
2. Vérifier la variable `REDIS_URL`
3. Vérifier les logs Rails pour les erreurs de connexion
