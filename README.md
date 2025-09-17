# Musik Motion

Aplicativo mobile desenvolvido em Flutter/Dart que simula uma loja de discos de vinil.
O app permite pesquisar discos reais pela API pública Discogs, aplicar filtros por gênero, adicionar itens ao carrinho e realizar um fluxo de compra simulado.
Também possui sistema de autenticação e cadastro de usuários com Firebase.

## Funcionalidades

### Autenticação de Usuários com Firebase Auth

 -Armazenamento de dados do usuário no Cloud Firestore

 -Pesquisa de álbuns na API do Discogs

 -Filtros por gênero (checklists dinâmicos)

 -Carrinho de compras persistente com opção de finalizar compra

 -Tela de perfil com edição de dados cadastrais

 -Navegação integrada com BottomNavigationBar

## Arquitetura

O projeto foi estruturado em três camadas:

Interface Gráfica (UI): telas e widgets em screens/

BLoC (Business Logic): gerenciamento de estado em bloc/

Data Provider: integrações com Firebase e API Discogs em data/

Essa divisão facilita a manutenção e evolução do aplicativo.

## Tecnologias Utilizadas

Flutter + Dart

Firebase Core

Firebase Auth

Cloud Firestore

HTTP (requisições à Discogs API)

flutter_bloc (gerência de estado)

## Dependências principais (pubspec.yaml):
firebase_core: ^3.13.1

firebase_auth: ^5.5.4

cloud_firestore: ^5.6.8

http: ^0.13.6

flutter_bloc: ^8.1.2

## Configuração do Projeto

### Clone este repositório:

git clone https://github.com/italovsc/musikMotionApp-Flutter.git


### Instale as dependências e rode:

flutter pub get


### Configure o Firebase no projeto:

flutterfire configure


### Execute o app:

flutter run

## API Discogs

A aplicação consome dados reais da Discogs API, uma API pública para discos, artistas e colecionadores.
As requisições são feitas via pacote http, retornando JSONs que populam a loja.
