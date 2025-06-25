# Infraestrutura Escalável na AWS com Auto Scaling e Classic Load Balancer

Este projeto tem como objetivo a criação de uma infraestrutura altamente disponível e escalável na AWS, utilizando Auto Scaling, Classic Load Balancer (CLB), VPC personalizada e monitoramento via CloudWatch.

## 📌 Objetivos

- Criar uma infraestrutura elástica e tolerante a falhas na AWS
- Implementar escalabilidade automática com Auto Scaling Groups
- Utilizar Classic Load Balancer para distribuir o tráfego
- Monitorar e reagir automaticamente a mudanças de carga com CloudWatch

### 1. **VPC e Sub-redes**
VPC e Sub-redes
Começamos criando uma VPC personalizada com duas sub-redes públicas, distribuídas em zonas de disponibilidade diferentes. Como não há necessidade de comunicação privada com a internet, não foi utilizado um NAT Gateway.
Essa configuração simples e eficiente atende ao propósito do projeto, resultando na estrutura de rede abaixo:

![imagem](/assets/vpc.png)

# 🔐 Configuração de Security Groups - Projeto com Auto Scaling e Load Balancer

Durante a construção da infraestrutura, foram criados dois **Security Groups (SGs)** para garantir o controle de tráfego adequado entre os componentes da aplicação:

## 1️⃣ Security Group - Load Balancer

Este grupo permite o tráfego externo para o Load Balancer. A regra de entrada libera o acesso público via HTTP:

### Regras de Entrada

| Tipo  | Protocolo | Faixa de Portas | Origem     |
|-------|-----------|------------------|------------|
| HTTP  | TCP       | 80               | 0.0.0.0/0  |

> 🔓 Essa configuração permite que qualquer usuário com acesso à internet possa acessar a aplicação via porta 80 (HTTP).

---

## 2️⃣ Security Group - EC2

Este grupo gerencia o tráfego que chega diretamente às instâncias EC2. As regras de entrada foram configuradas para aceitar requisições HTTP vindas apenas do Load Balancer e acesso SSH apenas a partir de um IP específico (o seu).

### Regras de Entrada

| Tipo  | Protocolo | Faixa de Portas | Origem             |
|-------|-----------|------------------|---------------------|
| HTTP  | TCP       | 80               | Security Group do LB |
| SSH   | TCP       | 22               | IP do Usuário        |

> 🔒 Acesso HTTP restrito ao Load Balancer e SSH restrito ao seu IP garantem uma camada extra de segurança.

---

Essas configurações são fundamentais para manter sua aplicação segura e funcional, permitindo somente o tráfego necessário e bloqueando acessos não autorizados. ✅

# ⚙️ Modelo de Execução - EC2 com Auto Scaling

## 💡 Visão Geral

Como parte da arquitetura proposta, foi necessário configurar o modelo de execução (Launch Template) para a instância EC2, atendendo aos seguintes requisitos:

- Associação de **IP público** à instância, garantindo conectividade externa quando necessário.
- Definição de um **script de inicialização (user_data)**, responsável por provisionar automaticamente o ambiente da instância no momento do lançamento.

## 🖥️ Configuração da EC2

Durante a criação do modelo de execução (Launch Template), foi ativada a opção de **IP público habilitado**, possibilitando o acesso à instância diretamente pela internet, caso necessário (como para testes ou SSH controlado).

![Lauch template](/assets/Lch%202.png)

## 🧾 Script de Inicialização (user_data)

Abaixo está o script usado no campo `user_data`, responsável por preparar automaticamente a instância para execução:

```bash
#!/bin/bash
# Atualiza os pacotes
apt update -y

# Instala o servidor Apache
apt install apache2 -y

# Inicia e habilita o Apache para iniciar com o sistema
systemctl start apache2
systemctl enable apache2

# Cria uma página HTML simples
echo "<!DOCTYPE html>
<html>
  <head>
    <title>Servidor EC2 em Auto Scaling</title>
  </head>
  <body>
    <h1>Instância criada com sucesso via Auto Scaling!</h1>
    <p>Apache2 está em execução.</p>
  </body>
</html>" > /var/www/html/index.html
```
# ⚖️ Configuração do Load Balancer - Classic Load Balancer (CLB)

## Visão Geral

Para atender aos requisitos do projeto, foi utilizado o **Classic Load Balancer (CLB)** da AWS. 

(IMAGEM AQUI)

O CLB foi configurado para distribuir o tráfego entre as instâncias EC2, garantindo alta disponibilidade e balanceamento eficiente da carga.

## Configuração do CLB

- **Integração com a VPC:** O Load Balancer foi conectado à VPC do projeto, utilizando as **subnets públicas** para garantir que ele possa receber requisições externas.
- **Security Group:** Foi associado um Security Group específico ao CLB para controlar o tráfego de entrada, permitindo o acesso HTTP na porta 80.

---

Essa configuração assegura que o tráfego dos usuários seja distribuído corretamente entre as instâncias EC2, garantindo melhor desempenho e tolerância a falhas no ambiente.


# 📈 Configuração do Auto Scaling e Monitoramento com CloudWatch

## Auto Scaling

Nesta etapa, configuramos o **Auto Scaling Group (ASG)** para gerenciar automaticamente a quantidade de instâncias EC2, garantindo escalabilidade conforme a demanda.

- Foi utilizado o **Launch Template** criado anteriormente para definir as configurações das instâncias.
- As **subnets públicas** foram selecionadas para associar o Auto Scaling ao ambiente de rede.
- O Auto Scaling foi configurado para operar em uma capacidade mínima de **1 instância** e máxima de **3 instâncias**, atendendo aos requisitos do projeto.
- O grupo foi conectado ao **Load Balancer (CLB)** para distribuir o tráfego entre as instâncias em escala.

## Monitoramento e Regras de Escala com CloudWatch

Para ajustar automaticamente o número de instâncias conforme a demanda, foram criadas políticas de escalonamento baseadas em métricas do **CloudWatch**:

| Ação               | Métrica                      | Condição                       |
|--------------------|------------------------------|-------------------------------|
| Aumentar instâncias | RequestCount por instância    | Maior que 10 requisições       |
| Diminuir instâncias | RequestCount por instância    | Menor que 5 requisições        |

Essas regras garantem que, quando a carga aumentar, novas instâncias sejam criadas para suportar o tráfego, e quando a demanda diminuir, o número de instâncias seja reduzido para otimizar custos.

---
![Cloudwatch](/assets/CLOUD%20IMAGEM%205.png)

Com essa configuração, a infraestrutura fica preparada para responder dinamicamente à variação do uso, mantendo a performance e a eficiência operacional.

# 🚀 Teste de Auto Scaling com Geração de Carga

## Gerando carga com a ferramenta *hey*

Para validar o funcionamento do Auto Scaling, utilizamos a ferramenta **hey**, que simula uma carga de requisições HTTP em um endpoint específico.

O comando utilizado foi:

```bash
hey -z 5m http://<DNS_DO_LOAD_BALANCER>/teste
```
Esse comando gera requisições contínuas durante 5 minutos para o DNS do Classic Load Balancer, simulando um aumento real de tráfego.

# 🚀 Resultados do Teste de Auto Scaling

## Visão Geral

Para validar a eficácia do Auto Scaling configurado no ambiente, realizamos um teste simulando um aumento de tráfego utilizando a ferramenta **hey**.

## Comportamento Observado

- **Escalabilidade automática:**  
  Conforme a carga de requisições aumentou, o Auto Scaling respondeu prontamente iniciando uma nova instância EC2 para suportar o aumento da demanda. Isso garantiu a continuidade do serviço sem degradação de desempenho.

- **Redução de recursos:**  
  Após o término do teste e a diminuição do volume de requisições, o sistema identificou a menor demanda e encerrou a instância adicional, retornando à capacidade mínima previamente configurada.

## Conclusão

O Auto Scaling demonstrou-se eficaz em ajustar dinamicamente a infraestrutura, garantindo alta disponibilidade, desempenho estável e otimização de custos conforme a necessidade do ambiente.

---


