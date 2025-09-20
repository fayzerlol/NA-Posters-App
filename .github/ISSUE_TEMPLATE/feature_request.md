name: Feature request
description: Solicitar funcionalidade
labels: ["type: feature"]
body:
  - type: input
    id: contexto
    attributes:
      label: Contexto
  - type: textarea
    id: descricao
    attributes:
      label: Descrição
      description: O que deve acontecer?
  - type: dropdown
    id: prioridade
    attributes:
      label: Prioridade
      options: [Alta, Média, Baixa]
