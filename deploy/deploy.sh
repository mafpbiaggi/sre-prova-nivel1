#! /bin/bash

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Uso: ./deploy.sh <versão>"
    echo "Exemplo: ./deploy.sh 1.0.0"
    exit 1
fi

echo "=== Deploy da versão $VERSION ==="

# 1. Build da nova imagem
echo "1. Construindo imagem ..."
docker build -t sre-app:$VERSION app/

# 2. Para o container antigo (se existir)
echo "2. Parando container ..."
docker stop app_sre 2>/dev/null || true
docker rm app_sre 2>/dev/null || true

# 3. Salva a versão anterior
echo "3. Salvando versão anterior ..."
docker tag sre-app:$VERSION sre-app:previous || true

# 4. Inicia o novo container
echo "4. Iniciando novo container..."
docker run -d --name app_sre -p 8080:8080 \
    -e APP_VERSION=$VERSION \
    sre-app:$VERSION

# 5. Aguarda inicialização
echo "5. Aguardando inicialição da aplicação ..."
sleep 5

# 6. Testa o health
echo "6. Testando estado da aplicação ..."
for i in {1..5}; do
    if curl -sf http://localhost:8080/health > /dev/null; then
        echo "✅ Deploy concluído com sucesso!"
        echo "Versão $VERSION está rodando"
        exit 0
    fi
    echo "Tentativa $i/5 falhou, aguardando..."
    sleep 2
done

echo "❌ Deploy falhou! Execute o rollback."
exit 1
