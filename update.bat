@echo off
REM Script para atualizar o repositório no GitHub
REM Este script executa: git add . && git commit -m "atualização do site" && git push

echo Iniciando atualizacao do repositorio...

REM Adicionar todas as mudanças
git add .

REM Comitar as mudanças
git commit -m "atualização do site"

REM Enviar para o repositório remoto
git push

echo Atualizacao concluida com sucesso!
pause
