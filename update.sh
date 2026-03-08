#!/bin/bash

# Script para atualizar o repositório no GitHub
# Este script executa: git add . && git commit -m "atualização do site" && git push

echo "Iniciando atualização do repositório..."

# Adicionar todas as mudanças
git add .

# Comitar as mudanças
git commit -m "atualização do site"

# Enviar para o repositório remoto
git push

echo "Atualização concluída com sucesso!"
